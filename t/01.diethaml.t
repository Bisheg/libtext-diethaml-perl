use strict;
use warnings;
use Carp;
use Test::More;
use Text::Diethaml;

plan tests => 25;

ok eval{ Text::Diethaml->can('convert') }, 'can convert method';

# Following tests according to HAML Reference page
# see L<http://haml-lang.com/docs/yardoc/file.HAML_REFERENCE.html>

{
# Plain Text

    # Diethaml strips any indentation blanks.

my $input = <<'END_HAML';
%gee
  %whiz
    Wow this is cool!
END_HAML

my $expected = <<'END_XML';
<gee>
<whiz>
Wow this is cool!
</whiz>
</gee>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Plain Text';
}

{
# Escaping: \

my $input = <<'END_HAML';
%title
  = $title
  \= $title
END_HAML

my $title = 'MyPage';

my $expected = <<'END_XML';
<title>
MyPage
= $title
</title>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Escaping: \\';
}

{
# HTML Element Name: %

my $input = <<'END_HAML';
%one
  %two
    %three Hey there
END_HAML

my $expected = <<'END_XML';
<one>
<two>
<three>Hey there</three>
</two>
</one>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Element Name: %';
}

{
# HTML Attributes: {}

    # Diethaml is not allow ruby's symbol notation as like as :xmlns

my $input = <<'END_HAML';
%html{xmlns => "http://www.w3.org/1999/xhtml", "xml:lang" => "en", lang => "en"}
END_HAML

my $expected = <<'END_XML';
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
</html>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'HTML Attributes: {}';
}

{
# HTML Attribute hashes can also be stretched out over multiple lines

    # Diethaml recognizes nestings of braces over 6 level.
    # It it not necessary:
    #   `newlines may only be placed immediately after commas'

my $input = <<'END_HAML';
%script{type => "text/javascript",
        src
          => "javascripts/script_@{[2 + 7]}"}
END_HAML

my $expected = <<'END_XML';
<script type="text/javascript" src="javascripts/script_9">
</script>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'HTML Attribute multiple lines';
}

# NOT Available: `:class and :id Attributes'
# NOT Available: `HTML-style Attributes: ()'

{
# Attribute Function

    # Since attribute hashes provide arguments lists in the function call,
    # it wants array for custom function.

my $html_attrs = sub{
    my($lang) = @_;
    $lang ||= 'en-US';
    return (
        'xmlns' => 'http://www.w3.org/1999/xhtml',
        'xml:lang' => $lang,
        'lang' => $lang,
    );
};

    # converted into C<< $_attr->($html_attrs->('fr-fr')) >>

my $input = <<'END_HAML';
%html{$html_attrs->('fr-fr')}
END_HAML

my $expected = <<'END_XML';
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr-fr" lang="fr-fr">
</html>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Attribute Function';
}

{
# You can use as many such attribute functions

    # from 0.004, attribute chooses the last one as similar as HAML.
    # <del>In spite of HAML, Diethaml's attribute builder chooses the first pair.</del>

my $hash1 = sub{
    return (bread => 'white', filling => 'peanut butter and jelly');
};

my $hash2 = sub{
    return (bread => 'whole wheat');
};

my $input = <<'END_HAML';
%sandwich{$hash1->(), $hash2->(), delicious => 'true'}/
END_HAML

my $expected = <<'END_XML';
<sandwich filling="peanut butter and jelly" bread="whole wheat" delicious="true" />
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Many attribute Function';
}

{
# Boolean Attributes

my $input = <<'END_HAML';
%input{selected => 1}
%input{checked => 0}
END_HAML

my $expected = <<'END_XML';
<input selected="selected" />
<input />
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Boolean Attributes';
}

# NOT Available: `HTML-style boolean attributes can be written just like HTML'
# NOT Available: `or using true and false'
# NOT Available: `HTML5 Custom Data Attributes'
# NOT Available: `Class and ID: . and #'
# NOT Available: `Implicit Div Elements'

{
# Self-Closing Tags: /

my $input = <<'END_HAML';
%br/
%meta{'http-equiv' => 'Content-Type', content => 'text/html'}/
%br
%meta{'http-equiv' => 'Content-Type', content => 'text/html'}
END_HAML

my $expected = <<'END_XML';
<br />
<meta http-equiv="Content-Type" content="text/html" />
<br />
<meta http-equiv="Content-Type" content="text/html" />
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Self-Closing Tags: /';
}

# NOT Available: `Whitespace Removal: > and <'
# NOT Available: `Object Reference: []'

{
# Doctype: !!!

my $input = <<'END_HAML';
!!! XML
!!!
%html
  %head
    %title Myspace
  %body
    %h1 I am the international space station
    %p Sign my guestbook
END_HAML

my $expected = <<'END_XML';
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Myspace</title>
</head>
<body>
<h1>I am the international space station</h1>
<p>Sign my guestbook</p>
</body>
</html>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Doctype: !!!';
}

# NOT Available: `You can also specify the specific doctype after the !!!'
# NOT Available: `you can specify which encoding should appear in the XML prolog'

{
# HTML Comments: /

my $input = <<'END_HAML';
%peanutbutterjelly
  / This is the peanutbutterjelly element
  I like sandwiches!
END_HAML

my $expected = <<'END_XML';
<peanutbutterjelly>
<!-- This is the peanutbutterjelly element -->
I like sandwiches!
</peanutbutterjelly>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'HTML Comments: /';
}

{
# HTML Comments: wrap indented sections

my $input = <<'END_HAML';
/
  %p This doesn't render...
  %div
    %h1 Because it's commented out!
END_HAML

my $expected = <<'END_XML';
<!--
<p>This doesn't render...</p>
<div>
<h1>Because it's commented out!</h1>
</div>
-->
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'HTML Comments: wrap indented sections';
}

{
# Conditional Comments: /[]

my $input = <<'END_HAML';
/[if IE]
  %a{ href => 'http://www.mozilla.com/en-US/firefox/' }
    %h1 Get Firefox
END_HAML

my $expected = <<'END_XML';
<!--[if IE]>
<a href="http://www.mozilla.com/en-US/firefox/">
<h1>Get Firefox</h1>
</a>
<![endif]-->
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Conditional Comments: /[]';
}

{
# Haml Comments: -#

my $input = <<'END_HAML';
%p foo
-# This is a comment
%p bar
END_HAML

my $expected = <<'END_XML';
<p>foo</p>
<p>bar</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Haml Comments: -#';
}

{
# Haml Comments: nest text beneath a silent comment

my $input = <<'END_HAML';
%p foo
-#
  This won't be displayed
    Nor will this
%p bar
END_HAML

my $expected = <<'END_XML';
<p>foo</p>
<p>bar</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Haml Comments: nest text beneath a silent comment';
}

{
# Inserting Perl: =

my $input = <<'END_HAML';
%p
  = join q( ), qw(hi there reader!)
  = "yo"
END_HAML

my $expected = <<'END_XML';
<p>
hi there reader!
yo
</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Inserting Perl: =';
}

{
# Escaping always: =

my $input = <<'END_HAML';
= '<script>alert("I\'m evil!");</script>'
END_HAML

my $expected = <<'END_XML';
&lt;script&gt;alert(&quot;I&#39;m evil!&quot;);&lt;/script&gt;
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Escaping always: =';
}

{
# = can also be used at the end of a tag

my $input = <<'END_HAML';
%p= "hello"
END_HAML

my $expected = <<'END_XML';
<p>hello</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, '= can also be used at the end of a tag';
}

# NOT Available: `A line of Perl code can be stretched over multiple lines'

{
# Running Perl: -

my $input = <<'END_HAML';
- my $foo = "hello";
- $foo .= " there";
- $foo .= " you!";
%p= $foo
END_HAML

my $expected = <<'END_XML';
<p>hello there you!</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Running Perl: -';
}

# NOT Available: `A line of Perl code can be stretched over multiple lines'

{
# Perl Blocks

my $input = <<'END_HAML';
- for my $i (42..47-1) {
  %p= $i
- }
%p See, I can count!
END_HAML

my $expected = <<'END_XML';
<p>42</p>
<p>43</p>
<p>44</p>
<p>45</p>
<p>46</p>
<p>See, I can count!</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Perl Blocks';
}

{
# Perl Blocks nested

my $input = <<'END_HAML';
%p
  - for (2) {
  -   if (/1/) {
    = "1!"
  -   } elsif (/2/) {
    = "2?"
  -   } elsif (/3/) {
    = "3."
  -   }
  - }
END_HAML

my $expected = <<'END_XML';
<p>
2?
</p>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Perl Blocks nested';
}

# NOT Available: `Whitespace Preservation: ~'
# NOT Available: `Ruby Interpolation: #{}'
# NOT Available: `Perl Interpolation: $var @{[expression]}'

{
# Escaping HTML: &=

my $input = <<'END_HAML';
&= "I like cheese & crackers"
END_HAML

my $expected = <<'END_XML';
I like cheese &amp; crackers
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Escaping HTML: &=';
}

# NOT Available: `& can also be used on its own'

{
# Unescaping HTML: !=

my $input = <<'END_HAML';
= "I feel <strong>!"
!= "I feel <strong>!"
END_HAML

my $expected = <<'END_XML';
I feel &lt;strong&gt;!
I feel <strong>!
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'Unescaping HTML: !=';
}

# NOT Available: `! can also be used on its own'
# NOT Available: `Filters'
# NOT Available: `Multiline: |'
# NOT Available: `Whitespace Preservation'
# NOT Available: `Helpers'

{
#and see the dirty (^^;) HTML output.
# original L<http://haml-lang.com/try.html>

my $input = <<'END_HAML';
!!!
%div{id => 'main'}
  %div{class => 'note'}
    %h2 Quick Notes
    %ul
      %li
        Haml is usually indented with two spaces,
        although more than two is allowed.
        You have to be consistent, though.
      %li
        The first character of any line is called
        the "control character" - it says "make a tag"
        or "run Ruby code" or all sorts of things.
      %li
        Haml takes care of nicely indenting your HTML.
      %li 
        Haml allows Ruby code and blocks.
        But not in this example.
        We turned it off for security.

  %div{class => 'note'}
    You can get more information by reading the
    %a{href => "/docs/yardoc/file.HAML_REFERENCE.html"}
      Official Haml Reference

  %div{class => 'note'}
    %p
      This example doesn't allow Ruby to be executed,
      but real Haml does.
    %p
      Ruby code is included by using = at the
      beginning of a line.
    %p
      Read the tutorial for more information.

END_HAML

my $expected = <<'END_XML';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<div id="main">
<div class="note">
<h2>Quick Notes</h2>
<ul>
<li>
Haml is usually indented with two spaces,
although more than two is allowed.
You have to be consistent, though.
</li>
<li>
The first character of any line is called
the "control character" - it says "make a tag"
or "run Ruby code" or all sorts of things.
</li>
<li>
Haml takes care of nicely indenting your HTML.
</li>
<li>
Haml allows Ruby code and blocks.
But not in this example.
We turned it off for security.
</li>
</ul>
</div>
<div class="note">
You can get more information by reading the
<a href="/docs/yardoc/file.HAML_REFERENCE.html">
Official Haml Reference
</a>
</div>
<div class="note">
<p>
This example doesn't allow Ruby to be executed,
but real Haml does.
</p>
<p>
Ruby code is included by using = at the
beginning of a line.
</p>
<p>
Read the tutorial for more information.
</p>
</div>
</div>
END_XML

    my $perl = Text::Diethaml->convert($input);
    my $proc = eval $perl or die "$@";
    is $proc->(), $expected, 'and see the dirty (^^;) HTML output';
}

done_testing;

