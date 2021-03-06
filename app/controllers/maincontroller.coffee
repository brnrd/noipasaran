marked = require 'marked'
_ = require 'underscore'
async = require 'async'

module.exports = (app) ->
	class app.maincontroller

	# NAVBAR CONTENT
		# INDEX
		@index = (req, res) ->
			res.render 'index', title: 'Home'
			
		@query = (req, res) ->
			queryStr = req.body.query
			# Check if the query is an IP or an URL
			app.ip.isIp queryStr, (isIp) ->
				if isIp
					res.redirect "/ip/#{queryStr}"
				else
					# Check if there is a . means it could be a URL
					dot = queryStr.split('.').length - 1
					if dot
						res.redirect "/url/#{queryStr}"
					else
						res.redirect "/404/#{queryStr}"

		@url = (req, res) ->
			app.ip.getIspOrCountry req, (data) ->
				if data.isIsp
					res.redirect "/url/#{req.params.url}/isp/#{data.isp}"
				else 
					res.redirect "/url/#{req.params.url}/country/#{data.country}"

		@isp = (req, res) ->
			isp = req.params.isp
			url = req.params.url
			url = "http://#{url}" if url.indexOf 'http', 0 < 0
			result = new Object()
			async.parallel [
				(callback) ->
					app.ip.getSite url, (site) ->
						if _.isEmpty site
							app.ip.getRawUrl url, (raw) ->
								res.redirect "/404/#{raw}" if _.isEmpty site
						else
							result.site = site
							callback()
				,(callback) ->
					app.dao.getServerByName isp, (servers) ->
						result.servers = servers
						callback()
			], (err) ->
				throw err if err
				app.ip.getLocalData result.site, url, result.servers, (data) ->
					result.answer = data.local
					app.ip.getRawUrl url, (raw) ->
						res.render 'isp', title: url, data: result, raw: raw 

		@country = (req, res) ->
			country = req.params.country
			url = req.params.url
			url = "http://#{url}" if url.indexOf 'http', 0 < 0
			result = new Object()
			async.parallel [
				(callback) ->
					app.ip.getSite url, (site) ->
						if _.isEmpty site
							app.ip.getRawUrl url, (raw) ->
								res.redirect "/404/#{raw}" if _.isEmpty site
						else
							result.site = site
							callback()
				,(callback) ->
					app.dao.getLocalServers country, (servers) ->
						result.servers = servers
						callback()
			], (err) ->
				throw err if err
				app.ip.getLocalData result.site, url, result.servers, (data) ->
					result.answer = data.local
					res.render 'country', title: url, data: result, country: country

		@ip = (req, res) ->
			# Get the ip
			ip = req.params.ip
			# Get the server from the db
			app.dao.getServerByIp ip, (server) ->
				# if there is a server with this ip
				if not _.isEmpty(server)
					# Build the static Maps URL
					app.staticmap.getMapUrl req, server[0].primary_ip, (data) ->
						# Get the distance between client and server
						app.distance.get data.server.latitude, data.server.longitude, data.client.latitude, data.client.longitude, (distance) ->
							res.render 'ip', title: ip, url: data.url, server: server[0], serverInfo: data.server, distance: distance
				# else redirect to 404 // EXAMINE THE POSSIBILITY TO RED TO HELP
				else
					app.dao.getSiteByIp ip, (site) ->
						if not _.isEmpty(site)
							res.redirect "/url/#{site[0].url}"
						else
							res.redirect "/404/#{ip}"

		# HELP
		@help = (req, res) ->
			res.render 'help', title: 'Help me'

		@helpPost = (req, res) ->
			app.dao.insertServer req.body, (newId) ->
				res.json newId

		# ABOUT
		@about = (req, res) ->
			res.render 'about', title: 'About'

		# DNS
		@dns = (req, res) ->
			app.dao.getServer req.params.id, (data) ->
				res.render 'dns', title: data[0].name, server: data[0]

		@google = (req, res) ->
			res.render 'google', title: '!Google', query: req.params.query

		@fourOfour = (req, res) ->
			something = req.params.something
			if something
				res.render '404', status: 404, title: '404.404.404.404', something: something
			else
				res.render '404', status: 404, title: '404.404.404.404', something: null
