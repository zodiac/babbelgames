import * as googleAnalytics from "../utility/googleAnalytics.jsx";

import EpisodeTileGallery from "./EpisodeTileGallery.jsx";
import NavigationBar from "./NavigationBar.jsx";
import ScreenPlayGame from "./ScreenPlayGame.jsx";

import React from "react";
import ReactDOM from "react-dom";
import {Router, Route} from "react-router";
import { browserHistory } from 'react-router'

// List of all the episode tiles that are availble on the starting page
const episodes = [
  {src: "friends.poster", isPoster: true},
  {src: "friends/s01e01", headline: "The One Where Monica Gets a Roommate"},
  {src: "friends/s01e02", headline: "The One With the Sonogram at the End"},
  {src: "friends/s01e03", headline: "The One With the Thumb"},
  {src: "sherlock.poster", isPoster: true},
  {src: "sherlock/s01e01", headline: "A Study in Pink"},
  {src: "sherlock/s01e02", headline: "The Blind Banker"}
];

var App = React.createClass({

	getIntialState: function() {
		return {
			currentEpisode: "friends/s01e01"
		};
	},

	render: function() {
		return (
			<div>
				<Router history={ browserHistory }>
					<Route path="/" component={NavigationBar}>
						<Route path="page/home" episodes={episodes} component={EpisodeTileGallery}>	</Route>
						<Route path="page/game/:dataSource" component={ScreenPlayGame}>	</Route>
						
					</Route>
				</Router>	    
			</div>
		);
	}

});

googleAnalytics.send();
ReactDOM.render(
  <App/>,
  document.getElementById('container')
);