#  Project: TweetScroller
#  Description: An infinite tweet scroller that automatically refreshes a collection of your favorite tweets.
#  Author: Divshot, Inc.
#  License: MIT

(($, window) ->
  pluginName = 'tweetscroller'
  document = window.document
  defaults =
    tweet: '.tweet'
    template: '#tweet-template'
    username: 'divshot'
    count: 50
    speed: 30 # ms, 30-80 ms recommended, slower = better performance
    autoplay: false # CPU intensive

  class TweetScroller
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options

      @_defaults = defaults
      @_name = pluginName
      @_initialTweetCount = 0

      @init()

    init: ->
      @checkDependencies()
      @getTweets()

    getTweets: ->
      $.getJSON "https://api.twitter.com/1/favorites.json?count=#{@options.count}&screen_name=#{@options.username}&callback=?", (data) =>
        
        $(@element).append('<div class="tweetscroller"></div>')
        @board = $(@element).find('.tweetscroller')

        $.each data, (i, tweet) =>
          tweet.created_at = new Date(Date.parse(tweet.created_at))
          tweet.created_at = moment(tweet.created_at).format('D MMM YY')
          source = $(@options.template).html()
          template = Handlebars.compile(source)
          @board.append(template(tweet))

        @board.masonry
          itemSelector: @options.tweet

        @_initialTweetCount = @board.find(@options.tweet).length
        @scrollTweets()

    scrollTweets: ->
      scrollActive = 0
      scrollInterval = null
      autoScroll = =>
        scrollActive = 1
        $(@element).scrollTop($(@element).scrollTop() + 1)

      # Scroll event to manage tweets
      $(@element).scroll (e) => @scrollRefresh(e)

      # Hover to scroll
      if !@options.autoplay
        $(@element).hoverIntent
          interval: 100
          over: =>
            if !scrollActive
              scrollInterval = setInterval(autoScroll, @options.speed)
          out: =>
            scrollActive = 0
            clearInterval(scrollInterval)
      else
        scrollInterval = setInterval(autoScroll, @options.speed)

    scrollRefresh: (e) ->
      _this = this
      if @board.parent()[0].scrollHeight - @board.parent().scrollTop() <= @board.parent().height()
        @board.find(@options.tweet).each (i) ->
          tweet = $(this).clone()
          _this.board.append(tweet).masonry('appended', tweet, true)
          if i <= _this.board.find('.tweet').length - _this._initialTweetCount
            $(this).remove()

    checkDependencies: ->
      if !Handlebars
        throw new Error('This plugin requires requires Handlebars: http://handlebarsjs.com')
      if typeof moment != 'function'
        throw new Error('This plugin requires requires Moment.js: http://momentjs.com')
      if !jQuery().masonry
        throw new Error('This plugin requires requires Masonry: http://masonry.desandro.com/')
      if !jQuery().hoverIntent
        throw new Error('This plugin requires hoverIntent: http://cherne.net/brian/resources/jquery.hoverIntent.html')

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new TweetScroller(@, options))
)(jQuery, window)