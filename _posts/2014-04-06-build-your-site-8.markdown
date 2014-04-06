---
layout: post
title:  "简历Github Flavored Markdown博客"
date:   2014-04-06 20:44:57
categories: diary
tags: blog
---

## 在rails系统中简单配置Markdown博客

markdown格式已经越来越普及，简单容易。rails中用于解析markdown格式的工具有很多，例如redcarpet就是一个例子。

简单在rails系统中配置与应用redcarpet如下。

### Gemfile添加相应gem

    gem 'redcarpet'

这里对于code block style并没有做太多的配置。对于不同类型的code block，需添加其他组件进行配置，具体可以搜索redcarpet关于不同语言的高亮的文章。

### 新建markdown的helper

app/helpers/markdown_helper.rb如下

```
module MarkdownHelper
  def markdown(text)
    unless @markdown
      # 选择自己需要的惊醒参数配置，若配置成github推荐的，可参考[Github Flavored Markdown][github-markdown]
      options = {
        hard_wrap: true, # 关于换行的设定
        filter_html: true, # 关于内嵌html文档
        autolink: true, # 关于连接
        no_intra_emphasis: true, # 关于单词内的强调符的解析
        strikethrough: true, # 关于删除符的解析
        fenced_code_blocks: true, # 等等参考[redcarpet][redcarpet]
        gh_blockcode: true,
        tables: true,
        footnotes: true,
        lax_spacing: true
      }

      renderer = Redcarpet::Render::HTML.new
      @markdown = Redcarpet::Markdown.new(renderer, options)
    end

    @markdown.render(text).force_encoding("UTF-8").html_safe
  end
end
```

然后就可以在view当中使用helper函数markdown对文档进行markdown式的解析了。

##参考链接

* [redcarpet][redcarpet]
* [Github Flavored Markdown][github-markdown]

[redcarpet]: https://github.com/vmg/redcarpet
[github-markdown]: https://help.github.com/articles/github-flavored-markdown
