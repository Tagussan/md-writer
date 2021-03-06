CmdModule = {} # To cache required modules

config = require "./config"
basicConfig =
  siteEngine:
    title: "Site Engine"
    type: "string"
    default: config.getDefault("siteEngine")
    enum: [config.getDefault("siteEngine"), config.engineNames()...]
  siteUrl:
    title: "Site URL"
    type: "string"
    default: config.getDefault("siteUrl")
  siteLocalDir:
    title: "Site Local Directory"
    description: "The absolute path to your site's local directory"
    type: "string"
    default: config.getDefault("siteLocalDir")
  siteDraftsDir:
    title: "Site Drafts Directory"
    description: "The relative path from your site's local directory"
    type: "string"
    default: config.getDefault("siteDraftsDir")
  sitePostsDir:
    title: "Site Posts Directory"
    description: "The relative path from your site's local directory"
    type: "string"
    default: config.getDefault("sitePostsDir")
  siteImagesDir:
    title: "Site Images Directory"
    description: "The relative path from your site's local directory"
    type: "string"
    default: config.getDefault("siteImagesDir")
  urlForTags:
    title: "URL to Tags JSON definitions"
    type: "string"
    default: config.getDefault("urlForTags")
  urlForPosts:
    title: "URL to Posts JSON definitions"
    type: "string"
    default: config.getDefault("urlForPosts")
  urlForCategories:
    title: "URL to Categories JSON definitions"
    type: "string"
    default: config.getDefault("urlForCategories")
  newDraftFileName:
    title: "New Draft File Name"
    type: "string"
    default: config.getCurrentDefault("newDraftFileName")
  newPostFileName:
    title: "New Post File Name"
    type: "string"
    default: config.getCurrentDefault("newPostFileName")
  fileExtension:
    title: "File Extension"
    type: "string"
    default: config.getCurrentDefault("fileExtension")
  tableAlignment:
    title: "Table Cell Alignment"
    type: "string"
    default: config.getDefault("tableAlignment")
    enum: ["empty", "left", "right", "center"]
  tableExtraPipes:
    title: "Table Extra Pipes"
    description: "Insert extra pipes at the start and the end of the table rows"
    type: "boolean"
    default: config.getDefault("tableExtraPipes")

module.exports =
  config: basicConfig

  activate: (state) ->
    workspaceCommands = {}
    editorCommands = {}

    # new-posts
    ["draft", "post"].forEach (file) =>
      workspaceCommands["mediawiki-writer:new-#{file}"] =
        @createCommand("./new-#{file}-view", optOutGrammars: true)

    # publishing
    workspaceCommands["mediawiki-writer:publish-draft"] =
      @createCommand("./publish-draft")

    # front-matter
    ["tags", "categories"].forEach (attr) =>
      editorCommands["mediawiki-writer:manage-post-#{attr}"] =
        @createCommand("./manage-post-#{attr}-view")

    # text
    ["code", "codeblock", "bold", "italic",
     "keystroke", "strikethrough"].forEach (style) =>
      editorCommands["mediawiki-writer:toggle-#{style}-text"] =
        @createCommand("./style-text", args: style)

    # line-wise
    ["h1", "h2", "h3", "h4", "h5", "ul", "ol",
     "task", "taskdone", "blockquote"].forEach (style) =>
      editorCommands["mediawiki-writer:toggle-#{style}"] =
        @createCommand("./style-line", args: style)

    # media
    ["link", "image", "table"].forEach (media) =>
      editorCommands["mediawiki-writer:insert-#{media}"] =
        @createCommand("./insert-#{media}-view")

    # helpers
    ["insert-new-line", "indent-list-line", "correct-order-list-numbers",
     "jump-to-previous-heading", "jump-to-next-heading",
     "jump-between-reference-definition", "jump-to-next-table-cell",
     "format-table"].forEach (command) =>
      editorCommands["mediawiki-writer:#{command}"] =
        @createHelper("./commands", command)

    # additional workspace helpers
    ["open-cheat-sheet", "create-default-keymaps"].forEach (command) =>
      workspaceCommands["mediawiki-writer:#{command}"] =
        @createHelper("./commands", command, optOutGrammars: true)

    @wsCommands = atom.commands.add "atom-workspace", workspaceCommands
    @edCommands = atom.commands.add "atom-text-editor", editorCommands

  createCommand: (path, options = {}) ->
    (e) =>
      unless options.optOutGrammars or @isMarkdown()
        return e.abortKeyBinding()

      CmdModule[path] ?= require(path)
      cmdInstance = new CmdModule[path](options.args)
      cmdInstance.display()

  createHelper: (path, cmd, options = {}) ->
    (e) =>
      unless options.optOutGrammars or @isMarkdown()
        return e.abortKeyBinding()

      CmdModule[path] ?= require(path)
      CmdModule[path].trigger(cmd)

  isMarkdown: ->
    editor = atom.workspace.getActiveTextEditor()
    return false unless editor?
    return editor.getGrammar().scopeName in config.get("grammars")

  deactivate: ->
    @wsCommands.dispose()
    @edCommands.dispose()

    CmdModule = {}
