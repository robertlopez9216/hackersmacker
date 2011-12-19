window._HS = (e) ->
    console.log(["HS", e]);
    
class window.HSGraph
    constructor: ->
        @decorateComments()
        
    decorateComments: ->
        @findCurrentUser()
        @findUsernames()
        @loadRelationships()
        @attachSharers()
        
    findCurrentUser: ->
        @me = $('.pagetop a[href^=user]').eq(0).attr('href').replace('user?id=', '')
        
    findUsernames: ->
        @usernames = _.uniq($('a[href^=user]').map ->
            $(@).attr('href').replace('user?id=', '')
        )
    
    loadRelationships: ->
        data = 
            usernames: @usernames
            me: @me
        $.ajax 
            url: 'http://nb.local.host:3030/load'
            data: data
            dataType: 'jsonp'
            jsonpCallback: "_HS"
            success: @attachRaters
        
    attachRaters: (graphJSON) =>
        @graph = JSON.parse(graphJSON)
        console.log 'graph', @graph
        new HSRater $($user), @me for $user in $('a[href^=user]')

    attachSharers: ->

class window.HSRater
    
    constructor: (@$user, @me, @username) ->
        @username = @$user.attr('href').replace('user?id=', '')
        @clear()
        @build()
        @attach()
        @handle()
        return
    
    clear: ->
        @$user.siblings('.HS-rater').remove()
        
    build: ->
        graphStatus = ""
        graphStatus = "HS-friend" if _.contains(HS.graph.friends, @username)
        graphStatus = "HS-foe" if _.contains(HS.graph.foes, @username)
        @rater = $ """<div class="HS-rater #{graphStatus}" data-username="#{@username}">
            <div class="HS-rater-button HS-rater-neutral"></div>
            <div class="HS-rater-button HS-rater-friend"></div>
            <div class="HS-rater-button HS-rater-foe"></div>
        </div>"""
        @neutral = $ '.HS-rater-neutral', @rater
        @foe     = $ '.HS-rater-foe',     @rater
        @friend  = $ '.HS-rater-friend',  @rater
        
    attach: ->
        @$user.after @rater
    
    handle: ->
        @animationOpts = 
            duration : 300,
            easing   : 'easeOutQuint'
            queue    : false
        @rater.bind('mouseenter', @expand)
              .bind('mouseleave', @collapse)
        _.each [@friend, @foe, @neutral], ($button) =>
            $button.bind 'click', (e) =>
                @save e
        return
                
    expand: =>
        clearTimeout @collapseTimeout
        @rater.animate  width: 70, @animationOpts
        @friend.animate left:  24, @animationOpts
        @foe.animate    left:  48, @animationOpts
    
    maybeCollapse: =>
        @collapseTimeout = setTimeout =>
            @collapse() if @collapseTimeout
        , 300
        
    collapse: =>
        @rater.animate  width: 22, @animationOpts
        @friend.animate left:  0,  @animationOpts
        @foe.animate    left:  0,  @animationOpts
        
    save: (e) ->
        $target = $ e.currentTarget
        if $target.hasClass('HS-rater-friend')
            @relationship = 'friend'
            HS.graph.friends.push(@username)
            HS.graph.foes = _.without HS.graph.foes, @username
        else if $target.hasClass('HS-rater-foe')
            @relationship = 'foe'
            HS.graph.friends = _.without HS.graph.friends, @username
            HS.graph.foes.push(@username)
        else
            HS.graph.friends = _.without HS.graph.friends, @username
            HS.graph.foes = _.without HS.graph.foes, @username
            @relationship = 'neutral'
            
        data = 
            username: @username
            me: @me
            relationship: @relationship
        $.ajax 
            url: 'http://nb.local.host:3030/save'
            data: data
            dataType: 'jsonp'
            jsonpCallback: "_HS_save"
        
        HS.graph.friends.push
        @reset()
        @resetDuplicates()
    
    reset: ->
        @rater.removeClass 'HS-foe'
        @rater.removeClass 'HS-friend'
        @rater.addClass    "HS-#{@relationship}"
        @collapse()
    
    resetDuplicates: ->
        $dupes = $("a[href^=\"user?id=#{@username}\"]").not(@$user)
        new HSRater $($dupe), @me for $dupe in $dupes
        
$(document).ready ->
    window.HS = new HSGraph()