package Text::Diethaml;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.001';
## no critic qw(ComplexRegex PunctuationVar)
my $XMLDECL = qq(<?xml version="1.0" encoding="utf-8" ?>\n);
my $DOCTYPE = <<'EOS';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
EOS
my %EMPTY = map { $_ => 1 } qw(meta img link br hr input area param col base);
my $HEADER = <<'EOS';
use strict;use warnings;no warnings 'redefine';use utf8;
my %special=('&'=>'&amp;','<'=>'&lt;','>'=>'&gt;','"'=>'&quot;',
"'"=>'&#39;','\\'=>'&#92;');
my %bool=qw(compact 1 nowrap 1 ismap 1 declare 1 noshade 1 checked 1
disabled 1 readonly 1 multiple 1 selected 1 noresize 1 defer 1);
my $escape=sub{my $t=defined $_[0]?$_[0]:q();$t=~s{([<>"'&\\])}{$special{$1}}egmsx;$t};
my $_attr=sub{
 my(@a)=@_;my($t,$id,@class,%a)=('');
 while(my($k,$v)=splice @a,0,2){
  if($k eq 'id'){defined $id or $id=$v}
  elsif($k eq 'class'){push @class,$v}
  elsif(! $bool{$k}){$a{$k}++or$t.=' '.$escape->($k).'="'.$escape->($v).'"'}
  elsif($v){$a{$k}++or$t.=' '.$escape->($k).'="'.$escape->($k).'"'}
 }
 if(@class){$t=' class="'.$escape->(join ' ',@class).'"'.$t}
 if(defined $id){$t=' id="'.$escape->($id).'"'.$t}
 $t;
};
EOS
my $CNTRL = '\\P{Print}\\p{Cntrl}'; # for perl-5.8
my $QQ_RE = qq/"[^$CNTRL"\\\\]*(?:\\\\[^$CNTRL][^$CNTRL"\\\\]*)*"/;
my $Q_RE  = qq/'[^$CNTRL'\\\\]*(?:\\\\[^$CNTRL][^$CNTRL'\\\\]*)*'/;
my $BRACE = _nest(6, qq/[^{}"']*(?:(?:[{](?R)[}]|$QQ_RE|$Q_RE)[^{}"']*)*/);
my $LEX = qr{ #0:skip
    ([ ]*)  #1:indent
    (?: !!! ([^\n]*) \n #2:doctype
    |   () (?:\n|-\# [^\n]*\n (?:(?:\1[ ][^\n]*|[ ]+)?\n)*)   #3:skip
    |   (?:%(\w+)(?:[{]($BRACE)[}])?(/?)|/((?:\[[^\n\]]+\])?))
            #4:tag #5:tag #6:tag ->tag  |   #7:tag ->cmt
        (?:([!&]?=)[ ]([^\n]+)?\n|[ ]([^\n]+)?\n|\n) #8:tag #9:tag #10:tag
    |   (-|[!&]?=)[ ]([^\n]+)\n             #11:expr #12:expr
    |   (?:\\(?=[!\-%!&=/ ]))?([^\n]+)\n    #13:text
    )
}msx;
my @TYPE = $LEX =~ m/\#[[:digit:]]+:([[:alnum:]]+)/gmsx;

sub convert {
    my($class, $haml) = @_;
    chomp $haml;
    $haml .= "\n";
    my $null = {map { $_ => q() } qw(type mark text sl open etag)};
    my($result, @stack) = (q());
    while ($haml =~ m{\G$LEX}gcmosx) {
        my $level = length $1;
        my $e = {%{$null}, 'type' => $TYPE[$#-], 'text' => $+};
        next if $e->{'type'} eq 'skip';
        if ($e->{'type'} eq 'tag') {
            if (defined $4) {
                @{$e}{qw(name attr sl etag)} = ($4, $5, $6, "</$4>");
                $e->{'sl'} ||= $EMPTY{$e->{'name'}} ? q(/) : q();
            }
            @{$e}{qw(opentag eoltag mark)} =
                  defined $8 ? (0, ! $e->{'sl'}, $e->{'sl'} ? q() : $8)
                : defined $10 ? (0, ! $e->{'sl'}, $e->{'sl'} ? q() : 'text')
                : (! $e->{'sl'}, 0, q());
            if (defined $7) {
                my($i, $f) = $7 ? ("$7>", '<![endif]') : (q(), q());
                my $s = $e->{'eoltag'} ? q( ) : q();
                @{$e}{qw(type cmt etag)} = ('cmt', "<!--$i$s", "$s$f\-->");
            }
        }
        $e->{'mark'} = $e->{'type'} eq 'expr' ? $11
            : $e->{'type'} eq 'text' ? 'text'
            : $e->{'mark'};
        chomp $e->{'text'};
        while (@stack >= 2 && $level < $stack[-1][0]) {
            if ($stack[-2][0] < $level) {
                $stack[-1][0] = $level;
                last;
            }
            if (my $prev = (pop @stack)->[1]) {
                $class->_inject(\$result, $prev, $null);
            }
        }
        if (! @stack || $stack[-1][1] && $stack[-1][0] < $level) {
            $class->_inject(\$result, $null, $e);
            push @stack, [$level, $e];
        }
        else {
            $class->_inject(\$result, $stack[-1][1], $e);
            @{$stack[-1]} = ($level, $e);
        }
    }
    while (@stack) {
        $class->_inject(\$result, (pop @stack)->[1], $null);
    }
    return $HEADER . qq/sub{my \x{24}_H='$result';return \x{24}_H;};\n/;
}

sub _inject {
    my($class, $r, $prev, $cur) = @_;
    if ($prev->{'opentag'}) {
        ${$r} .= _q($prev->{'etag'} . "\n");
    }
    if ($cur->{'type'} eq 'tag') {
        ${$r} .= join q(), _q("<$cur->{name}"),
            $cur->{'attr'} ? qq/'. \x{24}_attr->($cur->{attr}) .'/ : q(),
            $cur->{'sl'} ? qq( />\n) : q(>),
            $cur->{'opentag'} ? "\n" : q();
    }
    elsif ($cur->{'type'} eq 'cmt') {
        ${$r} .= _q($cur->{'cmt'}) . ($cur->{'opentag'} ? "\n" : q());
    }
    elsif ($cur->{'type'} eq 'doctype') {
        ${$r} .= _q($cur->{'text'} =~ m/XML/msx ? $XMLDECL : $DOCTYPE);
    }
    if (my $mark = $cur->{'mark'}) {
        my $escape = $mark eq q(!=) ? q() : "\x{24}escape->";
        ${$r} .= $mark eq 'text' ? _q(qq/$cur->{text}\n/)
            : $mark eq q(-) ? qq/'; $cur->{text}\n\x{24}_H .= '/
            : qq/' . $escape(join q(), $cur->{text}) . '\n/;
    }
    if ($cur->{'eoltag'}) {
        chomp ${$r};
        ${$r} .= _q($cur->{'etag'} . "\n");
    }
    return;
}

sub _q {
    my($s) = @_;
    $s =~ s{(['\\])}{\\$1}gmosx;
    return $s
}

sub _nest {
    my($n, $template) = @_;
    my $pattern = $template;
    for (1 .. $n) {
        $pattern =~ s/[(][?]R[)]/$template/gmsx;
    }
    $pattern =~ s/[(][?]R[)]//msx;
    return qr{$pattern}msx;
}

1;

# $Id$

__END__

=pod

=head1 NAME

Text::Diethaml - Subsets of Haml-Language to Perl source code

=head1 VERSION

0.001

=head1 SYNOPSIS

    use Text::Diethaml;
    use Encode;

    my $haml = <<'HAML';
    - my($title, $link) = @_;
    !!! XML
    !!!
    -# attribute provides
    -# $_attr->("xmlns"=>"http://www.w3.org/1999/xhtml", "xml:lang"=>"ja", lang=>"ja")
    %html{"xmlns"=>"http://www.w3.org/1999/xhtml", "xml:lang"=>"ja", lang=>"ja"}
      %head
        %meta{"http-equiv"=>"Content-Type", "content"=>"text/html; charset=UTF-8"}
        -# inserting provides
        -# $escape->(join q(), $title, " - ", "Example")
        %title= $title, " - ", "Example"
        /= 'generated: ', scalar gmtime, ' GMT'
      %body
        %h1
          %a{href => "/page/$link"}
            %img{"src"=>"/image/headermark.png","alt" => "*"}
            = $title
        %p
          != "<em>$title</em>. Every one."
        %p
          Haml gives me substitutions from CGI.pm html functions.
        %ul
          - for my $atom (qw(hydrogen helium litium)) {
          %li= $atom
          - }
    HAML

    my $jail = join q(), 'package Jail', $$, int rand 10000, q(;);
    my $perl = Text::Diethaml->convert($haml);
    my $proc = eval $jail . $perl or die "$@ :\n$perl";
    print encode('UTF-8', $proc->('Hello, World', 'hello'));

=head1 DESCRIPTION

This module provides you to convert Haml to Perl source code.

=head1 METHODS

=over

=item C<convert($haml_string)>

converts the given Haml source code to the perl's one.

=back

=head1 DEPENDENCIES

L<None>

=head1 LIMITATIONS

    Plain Text                - implemented
    Escaping: \               - implemented
    HTML Elements
      Element Name: %         - implemented
      Attributes: {}          - implemented but once (eval as perl's list)
      Attributes: ()          - NOT available
      class and id attributes with bracket  - NOT available
      Attribute Methods       - Array context
      Boolean Attributes      - works only in the XHTML way
      HTML 5 Custom Data Attributes - NOT available
      Class and ID: . and #   - NOT available
      Implicit Div Elements   - NOT available
      Self-Closing Tags: /    - implemented
      Whitespace Removal: > and <     - NOT available
      Object Reference: []    - NOT available
    Doctype: !!!              - Fixed XML utf-8 and XHTML Transitional DTD
    Comments:                 - implemented
    Conditional Comments: /[] - implemented
    Haml Comments: -#         - implemented
    Inserting Perl: =         - implemented only one line (always escaping)
    Running Perl: -           - implemented only one line
    Ruby Blocks               - NOT available
    Whitespace Preservation: ~   - NOT available
    Ruby Interpolation: #{}   - NOT available
    Perl Interpolation: @{[]} - NOT available
    Escaping HTML: &=         - implemented only one line
    Escaping HTML: &          - NOT available
    Unescaping HTML: !=       - implemented only one line
    Unescaping HTML: !        - NOT available
    Filters                   - NOT available
      :plain                  - NOT available
      :javascript             - NOT available
      :css                    - NOT available
      :cdata                  - NOT available
      :escaped                - NOT available
      :ruby                   - NOT available
      :perl                   - NOT available
      :preserve               - NOT available
      :erb                    - NOT available
      :sass                   - NOT available
      :textile                - NOT available
      :markdown               - NOT available
      :maruku                 - NOT available
      Custom Filters          - NOT available
    Multiline: |              - NOT available
    Whitespace Preservation   - NOT available
    Helpers                   - NOT available (Perl has lexical scope ;-)

=head1 SEE ALSO

L<Text::Haml> - full set implementation familiar as Ruby's original one.
L<http://haml-lang.com/>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

