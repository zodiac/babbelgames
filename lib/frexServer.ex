defmodule FrexServer do

  use Plug.Router
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison

  plug Ueberauth
  plug :match
  plug :dispatch

  get "/host" do
    conn |> IO.inspect
    send_resp(conn, 200, conn.host)
  end

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/episode_pairs.json" do
    contents = BabbelgamesDb.getAllEpisodePairs()
    |> Poison.encode!

    conn
    |> put_resp_content_type("text/html; charset=UTF-8")
    |> send_resp(200, contents)
  end

  def writeContentAddressable!(contents, type) do
    hash = :crypto.hash(:sha, contents)
    |> Base.encode16
    |> String.downcase

    filename = case type do
      :screenplay -> hash <> ".txt"
      :subtitles -> hash <> ".srt"
    end

    case type do
      :screenplay -> File.write!("data/screenplay/" <> filename, contents)
      :subtitles -> File.write!("data/subtitles/" <> filename, contents)
    end

    {:ok, filename}
  end

  def writeContentAddressableBinary!(encodedString) do
    hash = :crypto.hash(:sha, encodedString)
    |> Base.encode16
    |> String.downcase

    contents = Base.decode64!(encodedString)

    File.write!("frontend/img/" <> hash, contents)

    {:ok, hash}
  end

  post "/uploadEpisodePair" do

    %Plug.Conn{
      body_params: %{
        "english_screenplay_text" => englishScreenplayText,
        "english_srt_text" => englishSrtText,
        "l2_srt_text" => l2SrtText,
        "session_token" => sessionToken,
        "series_name" => seriesName,
        "episode_seqnumber" => episodeSeqnumber,
        "episode_title" => episodeTitle,
        "l2_code" => l2Code,
        "encoded_image" => encodedImage,
      }
    } = conn

    {:ok, englishScreenplayFilename} = writeContentAddressable!(englishScreenplayText, :screenplay)
    {:ok, englishSrtFilename} = writeContentAddressable!(englishSrtText, :subtitles)
    {:ok, l2SrtFilename} = writeContentAddressable!(l2SrtText, :subtitles)
    {:ok, imageFilename} = writeContentAddressableBinary!(encodedImage)

    {englishScreenplayFilename, englishSrtFilename, l2SrtFilename} |> IO.inspect

    {:ok, uid} = BabbelgamesDb.insertEpisodePair(
      sessionToken,
      seriesName,
      episodeSeqnumber,
      episodeTitle,
      imageFilename,
      "en",
      l2Code,
      englishScreenplayFilename,
      englishSrtFilename,
      l2SrtFilename
    )

    conn
    |> put_resp_content_type("application/json; charset=UTF-8")
    |> send_resp(200, "\"" <> uid <> "\"")
  end

  get "/auth/google/callback" do


    %Plug.Conn{
      assigns: %{
        ueberauth_auth: %Ueberauth.Auth{
          credentials: %Ueberauth.Auth.Credentials{
            token: token
          },
          info: %Ueberauth.Auth.Info{
            email: email,
            image: image,
            name: name,
          }
        }
      }
    } = conn

    BabbelgamesDb.addSession(email, token)
    BabbelgamesDb.addUser(email)

    contents = File.read!("frontend/drop_and_redirect.html")
    |> String.replace("{{userdata}}", Poison.encode!(%{
      "token" => token,
      "email" => email,
      "image_url" => image,
    }))

    conn
    |> put_resp_content_type("text/html; charset=UTF-8")
    |> send_resp(200, contents)
  end

  get "/auth/facebook/callback" do

    # TODO: generate a proper JWT token

    IO.inspect("hi")

    %Plug.Conn{
      assigns: %{
        ueberauth_auth: %Ueberauth.Auth{
          credentials: %Ueberauth.Auth.Credentials{
            token: token
          },
          info: %Ueberauth.Auth.Info{
            email: email,
            image: image,
            name: name
          }
        }
      }
    } = conn

    IO.inspect({email, image, name})

    BabbelgamesDb.addSession(email, token)
    BabbelgamesDb.addUser(email) # todo: check if user exists and log in

    contents = File.read!("frontend/drop_and_redirect.html")
    |> String.replace("{{userdata}}", Poison.encode!(%{
      "token" => token,
      "email" => email,
      "image_url" => image,
    }))

    conn
    |> put_resp_content_type("text/html; charset=UTF-8")
    |> send_resp(200, contents)
  end

  get "/" do
    contents = File.read!("frontend/index.html")
    conn
    |> put_resp_content_type("text/html; charset=UTF-8")
    |> put_resp_header("cache-control", "max-age=60")
    |> send_resp(200, contents)
  end

  get "/page/*glob" do
    contents = File.read!("frontend/index.html")
    conn
    |> put_resp_content_type("text/html; charset=UTF-8")
    |> put_resp_header("cache-control", "max-age=60")
    |> send_resp(200, contents)
  end

  get "/define_word/:word" do

    res = word
    |> String.replace(".", "")
    |> IO.inspect
    |> translateFrenchWord
    |> Poison.encode!(pretty: true)

    conn
    |> send_resp(200, res)
  end

  # Client reports that a correct match has been made
  post "progress/correctMatch" do

    %Plug.Conn{
      body_params: %{
        "line_number" => lineNumber,
        "tile_idx" => tileIdx,
        "session_token" => sessionToken,
        "episode_md5" => episodeMD5,
      }
    } = conn

    BabbelgamesDb.markCorrectPair(episodeMD5, sessionToken, lineNumber, tileIdx)

    conn |> send_resp(200, "OK")
  end

  get "progress/correctMatch/:episodeMD5" do

    %Plug.Conn{
      query_params: %{
        "session_token" => sessionToken
      }
    } = conn

    res = BabbelgamesDb.getCorrectPairs(episodeMD5, sessionToken)
    |> IO.inspect
    |> Poison.encode!(pretty: true)

    conn
    |> send_resp(200, res)
  end

  get "/sentenceMatchingGame/:uid" do

    # TODO(xuanji): rename to ignoreCache
    editMode = case conn do
      %Plug.Conn{
        query_params: %{
          "editMode" => "1"
        }
      } -> true
      _ -> false
    end

    cacheFilename = "cache/" <> uid
    if not editMode and File.exists?(cacheFilename) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, File.read!(cacheFilename))
    else

      x = uid |> BabbelgamesDb.getEpisodePairDataOf
      {:ok, %{
        "l1_srt_filename" => l1SrtFilename,
        "l2_srt_filename" => l2SrtFilename,
        "l1_screenplay_filename" => l1ScreenplayFilename,
        "episode_poster_filename" => episodePosterFilename,
        "episode_title" => episodeTitle,
        "episode_seqnumber" => episodeSeqnumber,
        "series_name" => seriesName,
        "l2_code" => l2Code,
      }} = x

      # %{"episode_poster_filename" => "friends-s01e01.jpg",
      #   "episode_seqnumber" => "s01e01",
      #   "episode_title" => "The One Where Monica Gets a Roommate", "l1_code" => "en",
      #   "l1_screenplay_filename" => "friends-s01e01.txt",
      #   "l1_srt_filename" => "en-friends-s01e01.srt", "l2_code" => "fr",
      #   "l2_srt_filename" => "fr-friends-s01e01.srt", "series_name" => "Friends",
      #   "uid" => "e1f985b1-f137-4d07-adc9-a014266981f3",
      #   "user_email" => "xuanji@gmail.com"}}


      "x" |> IO.inspect
      x |> IO.inspect

      entries = Srt.pairSrt(
        "data/subtitles/" <> l1SrtFilename,
        "data/subtitles/" <> l2SrtFilename,
        "data/screenplay/" <> l1ScreenplayFilename
      )
      |> Enum.map(fn x -> Tuple.to_list(x) end)


      jsonResult = Poison.encode!(%{
        "tileData" => entries,
        "screenplay" => File.read!("data/screenplay/" <> l1ScreenplayFilename),
        "metadata" => %{
          "title" => episodeTitle,
          "subtitle" => seriesName <> " " <> episodeSeqnumber,
          "poster_filename" => episodePosterFilename,
          "l2_code" => l2Code
        },
      }, pretty: true)

      File.write!(cacheFilename, jsonResult)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, jsonResult)
    end
  end

  def static(conn, contentType, filepath) do
    conn
    |> put_resp_header("cache-control", "max-age=60")
    |> put_resp_content_type(contentType)
    |> send_resp(200, File.read!(filepath))
  end

  get "/js/bundle.min.js" do
    conn
    conn
    |> put_resp_header("cache-control", "max-age=0")
    |> put_resp_content_type("application/javascript")
    |> send_resp(200, File.read!("frontend/js/bundle.min.js"))
  end

  get "/img/:filename" do
    static(conn, "image", "frontend/img/" <> filename)
  end

  get "/js/:filename" do
    static(conn, "application/javascript", "frontend/js/" <> filename)
  end

  get "/css/:filename" do
    static(conn, "text/css", "frontend/css/" <> filename)
  end

  def translateFrenchWord(word) do

    dbRes = BabbelgamesDb.defineWord(word, "fr")

    case dbRes do
      nil -> BabbelgamesDb.addDefinedWord(word, "fr", translateFrenchWordViaGoogle(word))
      word -> word
    end

  end

  def translateFrenchWordViaGoogle(word) do
    IO.inspect("hitting google api")
    api_key = "AIzaSyCelot8j13gsEeq898SZLycyq0GvcXb1PA"

    url = "https://www.googleapis.com/language/translate/v2?" <> URI.encode_query(%{
      "source" => "fr",
      "target" => "en",
      "key" => api_key,
      "q" => word
    })

    (HTTPotion.get url).body
    |> Poison.decode!
    |> Map.fetch!("data")
    |> Map.fetch!("translations")
    |> List.first
    |> Map.fetch!("translatedText")

  end

  get "translate/:words" do

    translatedWords = words
    |> String.split(",")
    |> Enum.map(fn w -> {w, translateFrenchWord(w)} end)
    |> Enum.into(%{})


    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(translatedWords))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
