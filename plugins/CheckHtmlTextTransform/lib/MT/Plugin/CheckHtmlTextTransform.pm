package MT::Plugin::CheckHtmlTextTransform;

use strict;
use warnings;
use utf8;

use MT::Util;
use File::Basename qw(basename dirname);

sub component {
    __PACKAGE__ =~ m/::([^:]+)\z/;
}

sub plugin {
    MT->component(component());
}

sub html_text_transform_traditional {
    my $str = shift;
    $str = '' unless defined $str;
    my @paras = split /\r?\n\r?\n/, $str;
    for my $p (@paras) {
        if ( $p
            !~ m@^</?(?:h1|h2|h3|h4|h5|h6|table|ol|dl|ul|menu|dir|p|pre|center|form|fieldset|select|blockquote|address|div|hr)@
            )
        {
            $p =~ s!\r?\n!<br />\n!g;
            $p = "<p>$p</p>";
        }
    }
    join "\n\n", @paras;
}

sub _change_lf {
    my $str = shift;
    $str =~ s/\n/\x00/g;
    $str;
}

sub html_text_transform_r4607 {
    my $str = shift;
    $str = '' unless defined $str;
    my $tags = qr!(?:h1|h2|h3|h4|h5|h6|table|ol|dl|ul|li|menu|dir|p|pre|center|form|fieldset|select|blockquote|address|div|hr)!;
    my @paras = split /\r?\n\r?\n/, $str;
    for my $i ( 0 .. @paras - 1 ) {
        ## If the paragraph does not start nor end with a block(-ish) tag,
        ## then wrap it with <p>.
        if ( $paras[$i] !~ m!(?:^</?$tags|</$tags>$)! ) {
            $paras[$i] = "<p>$paras[$i]</p>";
        }
        ## If a line in the paragraph does not end with a tag,
        ## append a <br>. (Let's hope it does not end with an inline tag.)
        $paras[$i] =~ s|(?<!>)\r?\n|<br />\n|g;

        ## Special case: if the paragraph starts with a block(-ish) tag,
        ## and does not end with a closing tag, then the paragraph should have
        ## two <br>s to make a blank line, but only when the next paragraph
        ## does not start with a block(-ish) tag and it ends with a block(-ish)
        ## tag that prevents wrapping.
        if ( $paras[$i] =~ m|(?<!>)\z| ) {
            my $next = $i < @paras - 1 ? $paras[$i + 1] : undef;
            if ( defined $next && $next =~ m!</$tags>$! && $next !~ m!^</?$tags! ) {
                $paras[$i] .= '<br /><br />';
            }
        }
    }
    join "\n\n", @paras;
}

sub html_text_transform_r4608 {
    my $str = shift;
    $str = '' unless defined $str;
    my $tags = qr!(?:h1|h2|h3|h4|h5|h6|table|ol|dl|ul|li|menu|dir|p|pre|center|form|fieldset|select|blockquote|address|div|hr|script|style)!;
    $str =~ s/\r\n/\n/gs;
    my $special_tags = qr!(?:script|style|pre)!;
    $str =~ s{(<!--.*?-->|<($special_tags).*?</\2)}{_change_lf($1)}ges;
    my @paras = split /\n\n/, $str;
    for my $i ( 0 .. @paras - 1 ) {
        ## If the paragraph does not start nor end with a block(-ish) tag,
        ## then wrap it with <p>.
        if ( $paras[$i] !~ m{(?:^(?:</?$tags|<!--)|(?:</$tags>|-->)$)} ) {
            $paras[$i] = "<p>$paras[$i]</p>";
        }
        ## If a line in the paragraph does not end with a tag,
        ## append a <br>. (Let's hope it does not end with an inline tag.)
        $paras[$i] =~ s|(?<!>)\n|<br />\n|g;

        ## Special case: if the paragraph starts with a block(-ish) tag,
        ## and does not end with a closing tag, then the paragraph should have
        ## two <br>s to make a blank line, but only when the next paragraph
        ## does not start with a block(-ish) tag and it ends with a block(-ish)
        ## tag that prevents wrapping.
        if ( $paras[$i] =~ m|(?<!>)\z| ) {
            my $next = $i < @paras - 1 ? $paras[$i + 1] : undef;
            if ( defined $next && $next =~ m!</$tags>$! && $next !~ m!^</?$tags! ) {
                $paras[$i] .= '<br /><br />';
            }
        }
    }
    $str = join "\n\n", @paras;
    $str =~ s/\x00/\n/g;
    $str;
}

sub html_text_transform_r4610 {
    my $str = shift;
    $str = '' unless defined $str;
    my $tags = qr!(?:h1|h2|h3|h4|h5|h6|table|ol|dl|ul|li|menu|dir|p|pre|center|form|fieldset|select|blockquote|address|div|hr|script|style)!;
    $str =~ s/\r\n/\n/gs;
    my $special_tags = qr!(?:script|style|pre)!;
    $str =~ s{(<!--.*?-->|<($special_tags).*?</\2)}{_change_lf($1)}ges;
    my @paras = split /\n\n/, $str;
    for my $i ( 0 .. @paras - 1 ) {
        ## If the paragraph does not start nor end with a block(-ish) tag,
        ## then wrap it with <p> (later).
        my $wrap = 0;
        if ( $paras[$i] !~ m{(?:^</?$tags|</$tags>$|\A(?><!--.*?-->)+\z)} ) {
            $wrap = 1;
        }

        ## If a line in the paragraph does not end with a block tag,
        ## append a <br>.
        my @lines = split /\n/, $paras[$i];
        my $last_line = pop @lines;  ## but not for the last line
        for my $line (@lines) {
            $line .= "<br />" unless $line =~ m{(?:</?$tags\s*[^<>]*/?>|\A(?><!--.*?-->)+\z)$};
        }

        ## Special case: if the paragraph starts with a block(-ish) tag,
        ## and does not end with a closing tag, then the paragraph should have
        ## two <br>s to make a blank line, but only when the next paragraph
        ## does not start with a block(-ish) tag and it ends with a block(-ish)
        ## tag that prevents wrapping.
        if ( !$wrap and defined $last_line && $last_line !~ m!(?:</?$tags\s*/?>|-->)\z! ) {
            my $next = $i < @paras - 1 ? $paras[$i + 1] : undef;
            if ( defined $next && $next =~ m!</$tags>$! && $next !~ m!^</?$tags! ) {
                $last_line .= '<br /><br />';
            }
        }

        push @lines, $last_line if defined $last_line;
        $paras[$i] = join "\n", @lines;
        if ($wrap) {
            $paras[$i] = "<p>$paras[$i]</p>";
        }
    }
    $str = join "\n\n", @paras;
    $str =~ s/\x00/\n/g;
    $str;
}

sub checkhtmltexttransform {
    my $app = shift;
    $app->user->is_superuser
        or die plugin()->translate('System administor permission is required.');

    my $tmpl = plugin()->load_tmpl('checkhtmltexttransform.tmpl');

    my @entries = map { +{ blog_id => $_->blog_id, id => $_->id, } } $app->model('entry')->load(
        { convert_breaks => '__default__' },
        { fetchonly => [ 'blog_id', 'id' ] }
    );

    $tmpl->param(
        {
            entries => \@entries,
        }
    );

    $tmpl;
}

sub checkhtmltexttransform_transform {
    my $app = shift;
    $app->user->is_superuser
        or die plugin()->translate('System administor permission is required.');

    my $id = $app->param('id');
    my $formats = $app->param('formats');

    die unless $id =~ m/\A[0-9]+\z/ && $formats =~ m/\A(?:(?:traditional|r[0-9]+),?)+\z/;

    my $entry = $app->model('entry')->load($id);
    my $src = $entry->text . "\n" . $entry->text_more;

    my @list = map {
        my $m = "html_text_transform_$_";
        no strict "refs";
        &$m($src);
    } split /,/, $formats;

    $app->set_header( 'X-Content-Type-Options' => 'nosniff' );
    $app->send_http_header("application/json");
    $app->{no_print_body} = 1;
    $app->print_encode(MT::Util::to_json( +{ entries => [ \@list ] } ));

    return undef;
}

1;
