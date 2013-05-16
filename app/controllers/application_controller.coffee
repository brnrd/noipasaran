request = require 'request'
marked = require 'marked'

module.exports = (app) ->
	class app.ApplicationController

	# NAVBAR CONTENT
		# INDEX
		@index = (req, res) ->
			res.render 'index', view: 'index', title: 'Home'
			
		@query = (req, res) ->
			queryStr = req.body.query
			console.log 'QUERY:' + queryStr
			# Check if the query is an IP or an URL
			app.ipmanip.isIp queryStr, (isIp) ->
				if isIp
					res.redirect '/ip/' + queryStr
				else
					res.redirect '/url/' + queryStr

		@url = (req, res) ->
			url = req.params.url
			app.ipmanip.getClientIP req, (ip) ->
				#ip = '81.247.34.211'
				app.ipmanip.getIpCountry ip, (country) ->
					console.log 'country: ' + country
					app.dao.getServersWhereLocation country, (servers) ->
						console.log servers
						app.ipmanip.resolveServers url, servers, (resolved) ->
							console.log 'RESOLVED :'
							console.log resolved
							if resolved
								# Insert the url into the db with his IP
								resip = '0.0.0.0'

								app.dao.insertSite url, resip, (id) ->
									console.log 'Site ' + id + ' inserted'
							else
								res.redirect '/google/' + url
							res.render 'url', view: 'url', title: 'Result', url: url, clientip: ip, country: country, result: resolved

		@ip = (req, res) ->
			res.render 'ip', view 'ip'

		# HELP
		@help = (req, res) ->
			res.render 'help', view: 'help', title: 'Help'

		@helpPost = (req, res) ->
			app.dao.insertServer req.body, (newId) ->
				res.json newId

		# ABOUT
		@about = (req, res) ->
			res.render 'about', view: 'about', title: 'About'

		# DNS
		@dns = (req, res) ->
			app.dao.getServer req.params.id, (data) ->
				res.render 'dns', view: 'dns', title: data[0].name, server: data[0]

		#ADMIN
		@admin = (req, res) ->
			res.render 'admin', view: 'admin', title: 'Admin'

		# Admin servers
		@adminservers = (req, res) ->
			app.dao.getServers (data) ->
				res.render 'adminservers', view: 'adminservers', title: 'Servers', servers: data

		@valServer = (req, res) ->
			app.dao.valServer req.params.id, (data) ->
				res.json data

		@unvalServer = (req, res) ->
			app.dao.unvalServer req.params.id, (data) ->
				res.json data

		@editServer = (req, res) ->
			app.dao.editServer req.body, (data) ->
				res.json data

		@delServer = (req, res) ->
			app.dao.delServer req.params.id, (data) ->
				res.redirect '/admin/servers'

		@editServerModal = (req, res) ->
			app.dao.getServer req.params.id, (data) ->
				res.render 'editservermodal', view: 'editservermodal', server: data[0]

		# Admin sites	
		@adminsites = (req, res) ->
			app.dao.getSites (data) ->
				res.render 'adminsites', view: 'adminsites', title: 'Sites', sites: data

		@google = (req, res) ->
			res.render 'google', view: 'google', title: '!Google', query: req.params.query


