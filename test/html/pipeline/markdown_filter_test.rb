# frozen_string_literal: true

require 'test_helper'

MarkdownFilter = HTML::Pipeline::MarkdownFilter

class HTML::Pipeline::MarkdownFilterTest < Minitest::Test
  def setup
    @haiku =
      "Pointing at the moon\n" \
      "Reminded of simple things\n" \
      'Moments matter most'
    @links =
      'See http://example.org/ for more info'
    @code =
      "```\n" \
      'def hello()' \
      "  'world'" \
      'end' \
      '```'
  end

  def test_fails_when_given_a_documentfragment
    body = '<p>heyo</p>'
    doc  = HTML::Pipeline.parse(body)
    assert_raises(TypeError) { MarkdownFilter.call(doc, {}) }
  end

  def test_gfm_enabled_by_default
    doc = MarkdownFilter.to_document(@haiku, {})
    assert doc.is_a?(HTML::Pipeline::DocumentFragment)
    assert_equal 2, doc.search('br').size
  end

  def test_disabling_gfm
    doc = MarkdownFilter.to_document(@haiku, gfm: false)
    assert doc.is_a?(HTML::Pipeline::DocumentFragment)
    assert_equal 0, doc.search('br').size
  end

  def test_fenced_code_blocks
    doc = MarkdownFilter.to_document(@code)
    assert doc.is_a?(HTML::Pipeline::DocumentFragment)
    assert_equal 1, doc.search('pre').size
  end

  def test_fenced_code_blocks_with_language
    doc = MarkdownFilter.to_document(@code.sub('```', '``` ruby'))
    assert doc.is_a?(HTML::Pipeline::DocumentFragment)
    assert_equal 1, doc.search('pre').size
    assert_equal 'ruby', doc.search('pre').first['lang']
  end

  def test_standard_extensions
    iframe = "<iframe src='http://www.google.com'></iframe>"
    iframe_escaped = "&lt;iframe src='http://www.google.com'>&lt;/iframe>"
    doc = MarkdownFilter.new(iframe, unsafe: true).call
    assert_equal(doc, iframe_escaped)
  end

  def test_changing_extensions
    iframe = "<iframe src='http://www.google.com'></iframe>"
    doc = MarkdownFilter.new(iframe, commonmarker_extensions: [], unsafe: true).call
    assert_equal(doc, iframe)
  end
end

class GFMTest < Minitest::Test
  def gfm(text)
    MarkdownFilter.call(text, gfm: true, unsafe: true)
  end

  def test_not_touch_single_underscores_inside_words
    assert_equal '<p>foo_bar</p>',
                 gfm('foo_bar')
  end

  def test_not_touch_underscores_in_code_blocks
    assert_equal "<pre><code>foo_bar_baz\n</code></pre>",
                 gfm('    foo_bar_baz')
  end

  def test_not_touch_underscores_in_pre_blocks
    assert_equal "<pre>\nfoo_bar_baz\n</pre>",
                 gfm("<pre>\nfoo_bar_baz\n</pre>")
  end

  def test_not_touch_two_or_more_underscores_inside_words
    assert_equal '<p>foo_bar_baz</p>',
                 gfm('foo_bar_baz')
  end

  def test_turn_newlines_into_br_tags_in_simple_cases
    assert_equal "<p>foo<br />\nbar</p>",
                 gfm("foo\nbar")
  end

  def test_convert_newlines_in_all_groups
    assert_equal "<p>apple<br />\npear<br />\norange</p>\n" \
                 "<p>ruby<br />\npython<br />\nerlang</p>",
                 gfm("apple\npear\norange\n\nruby\npython\nerlang")
  end

  def test_convert_newlines_in_even_long_groups
    assert_equal "<p>apple<br />\npear<br />\norange<br />\nbanana</p>\n" \
                 "<p>ruby<br />\npython<br />\nerlang</p>",
                 gfm("apple\npear\norange\nbanana\n\nruby\npython\nerlang")
  end

  def test_not_convert_newlines_in_lists
    assert_equal "<h1>foo</h1>\n<h1>bar</h1>",
                 gfm("# foo\n# bar")
    assert_equal "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>",
                 gfm("* foo\n* bar")
  end
end
