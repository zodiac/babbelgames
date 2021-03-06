import $ from "jquery";
import React from "react";
import EpisodeTile from "./EpisodeTile.jsx";
import styles from "../../css/episodeTileGallery.css";

const EpisodeTileGallery = React.createClass({

  getInitialState: function () {
    return {
      srcOfMousedOverTile: null,
    };
  },

  handleMouseOverTile: function(src) {
    this.setState({ srcOfMousedOverTile: src });
  },

  handleMouseOutTile: function(src) {
    if (this.state.srcOfMousedOverTile === src) {
      this.setState({ srcOfMousedOverTile: null });
    }
  },

  render: function () {

    return <div className={styles.flexContainer}>
      <div className={styles.episodeTileContainer}>
        {this.props.episodePairs.map((ep, i) => <EpisodeTile
          key={i}
          src={ep.uid}
          imageSrc={'/' + ep.episode_poster_filename}
          onMouseEnter={this.handleMouseOverTile}
          onMouseLeave={this.handleMouseOutTile}
          isPoster={false}
          headline={ep.episode_title}
          href={"/page/game/" + ep.uid}
          l2Code={ep.l2_code}
          srcOfMousedOverTile={this.state.srcOfMousedOverTile} />
        )}
      </div>
      <div className={styles.additionalInfoFooter}>
        <div>Copyright &copy; 2016 BabbelGames</div>
      </div>
    </div>

    return <div></div>
  }

});

const EpisodeTileGalleryContainer = React.createClass({
  getInitialState: function () {
    return {
      'episodePairs': []
    }
  },
  componentDidMount: function () {
    $.getJSON('/episode_pairs.json', (res) => {
      this.setState({
        'episodePairs': res
      });
    });
  },
  render: function () {
    return <EpisodeTileGallery
      episodePairs={this.state.episodePairs} />
  }
});

export default EpisodeTileGalleryContainer;
