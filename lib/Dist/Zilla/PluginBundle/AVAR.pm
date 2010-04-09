package Dist::Zilla::PluginBundle::AVAR;

use 5.10.0;
use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::Plugin::VersionFromPrev;
use Dist::Zilla::Plugin::AutoPrereq;
use Dist::Zilla::Plugin::MetaNoIndex;
use Dist::Zilla::Plugin::ReadmeFromPod;
use Dist::Zilla::Plugin::MakeMaker::Awesome;
use Dist::Zilla::Plugin::CompileTests;

sub bundle_config {
    my ($self, $section) = @_;

    my $args        = $section->{payload};
    my $dist        = $args->{dist} // die "You must supply a dist =, it's equivalent to what you supply as name =";
    my $ldist       = lc $dist;
    my $github_user = $args->{github_user} // 'avar';
    my $no_a_pre    = $args->{no_AutoPrereq} // 0;
    my $use_mm      = $args->{use_MakeMaker} // 1;
    my $use_ct      = $args->{use_CompileTests} // 1;
    my $bugtracker  = $args->{bugtracker}  // 'github';
    my $tracker;

    given ($bugtracker) {
        when ('github') { $tracker = "http://github.com/$github_user/$ldist/issues" }
        when ('rt')     { $tracker = "https://rt.cpan.org/Public/Dist/Display.html?Name=$dist" }
        default         { $tracker = $bugtracker }
    }

    my @plugins = Dist::Zilla::PluginBundle::Filter->bundle_config({
        name    => $section->{name} . '/@Classic',
        payload => {
            bundle => '@Classic',
            remove => [
                # Don't add a =head1 VERSION
                'PodVersion',
                # This will inevitably whine about completely reasonable stuff
                'PodCoverageTests',
                # Use my MakeMaker
                'MakeMaker',
            ],
        },
    });

    my $prefix = 'Dist::Zilla::Plugin::';
    my @extra = map {[ "$section->{name}/$_->[0]" => "$prefix$_->[0]" => $_->[1] ]}
    (
        [ VersionFromPrev => {} ],
        ($no_a_pre
         ? ()
         : ([ AutoPrereq  => { } ])),
        [ MetaJSON     => { } ],
        [
            MetaNoIndex => {
                # Ignore these if they're there
                directory => [ map { -d $_ ? $_ : () } qw( inc t xt utils example examples ) ],
            }
        ],
        # Produce README from lib/
        [ ReadmeFromPod => {} ],
        [
            MetaResources => {
                homepage => "http://search.cpan.org/dist/$dist/",
                bugtracker => $tracker,
                repository => "http://github.com/$github_user/$ldist",
                license => 'http://dev.perl.org/licenses/',
                Ratings => "http://cpanratings.perl.org/d/$dist",
            }

        ],
        # Bump the Changlog
        [
            NextRelease => {
                format => '%-2v %{yyyy-MM-dd HH:mm:ss}d',
            }
        ],

        # Maybe use MakeMaker, maybe not
        ($use_mm
         ? ([ MakeMaker  => { } ])
         : ()),

        # Maybe CompileTests
        ($use_ct
         ? ([ CompileTests  => { } ])
         : ()),
    );
    push @plugins, @extra;

    push @plugins, Dist::Zilla::PluginBundle::Git->bundle_config({
        name    => "$section->{name}/\@Git",
        payload => {
            tag_format => '%v',
        },
    });

    return @plugins;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Dist::Zilla::PluginBundle::AVAR - Use L<Dist::Zilla> like AVAR does

=head1 DESCRIPTION

This is the plugin bundle that AVAR uses. Use it as:

    [@AVAR]
    ;; same as `name' earlier in the dist.ini, repeated due to
    ;; limitations of the Dist::Zilla plugin interface
    dist = MyDist
    ;; If you're not avar
    github_user = imposter

It's equivalent to:

    [@Filter]
    bundle = @Classic
    remove = PodVersion
    remove = PodCoverageTests
    
    [VersionFromPrev]
    [AutoPrereq]
    [MetaJSON]

    [MetaNoIndex]
    ;; Only added if these directories exist
    directory = inc
    directory = t
    directory = xt
    directory = utils
    directory = example
    directory = examples
    
    [ReadmeFromPod]

    [MetaResources]
    ;; $github_user is 'avar' by default, $lc_dist is lc($dist)
    homepage   = http://search.cpan.org/dist/$dist/
    bugtracker = http://github.com/$github_user/$lc_dist/issues
    repository = http://github.com/$github_user/$lc_dist
    license    = http://dev.perl.org/licenses/
    Ratings    = http://cpanratings.perl.org/d/$dist
    
    [NextRelease]
    format = %-2v %{yyyy-MM-dd HH:mm:ss}d
    
    [@Git]
    tag_format = %v

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
    
=cut
