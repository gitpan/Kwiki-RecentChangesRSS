# $Id: RecentChangesRSS.pm,v 1.10 2004/07/20 22:31:54 peregrin Exp $
package Kwiki::RecentChangesRSS;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use POSIX qw(strftime);
use Time::Local;
our $VERSION = '0.02';

const class_id        => 'RecentChangesRSS';
const class_title     => 'RecentChangesRSS';
const screen_template => 'rss_screen.xml';
const config_file     => 'rss.yaml';

sub register {
  my $registry = shift;
  $registry->add(action   => 'RecentChangesRSS');
  $registry->add(toolbar  => 'rss_button',
		 template => 'rss_button.html',
		);
}
sub RecentChangesRSS {
  use XML::RSS;
  my %channel_info = (link           => $self->config->rss_link,
		      copyright      => $self->config->rss_copyright,
		      language       => $self->config->rss_language,
		      description    => $self->config->rss_description,
		      title          => $self->config->rss_title,
		      docs           => $self->config->rss_docs,
		      generator      => $self->config->rss_generator,
		      managingEditor => $self->config->rss_managingEditor,
		      webMaster      => $self->config->rss_webMaster,
		      category       => $self->config->rss_category,
		      image          => $self->config->rss_image,
		      );
  my $rss = new XML::RSS (version => '2.0');
  while (my ($key,$value) = each %channel_info) {
    $rss->channel($key => $value);
  }

  my $depth_object = $self->preferences->recent_changes_depth;
  my $depth = $self->config->rss_depth;
  my $label = +{@{$depth_object->choices}}->{$depth};

  my $pages;
  @$pages = sort {
    $b->modified_time <=> $a->modified_time;
  } $self->pages->all_since($depth * 1440);

  $ENV{SERVER_PROTOCOL} =~ m!^(\w+)/!;
  my $protocol = $1;
  foreach my $page (@$pages) {
    $rss->add_item(title => $page->id,
		   link => "\L$protocol" . "://" . $ENV{SERVER_NAME} .
		           $page->hub->config->script_name . "?" . $page->id,
		   description => "Last edited by " . $page->metadata->edit_by,
		   pubDate => strftime("%a, %d %b %Y %T %Z",
				       localtime($page->modified_time)),
		  );
  }
  #
  # lastBuildDate is the time the content last changed, therefore the time of
  # the latest wiki page
  $rss->channel(lastBuildDate => 
		strftime("%a, %d %b %Y %T %Z",
			 localtime($pages->[0]->modified_time)));

  # Override to set the correct Content-Type header
 { 
    no warnings 'redefine'; 
    eval "*Spoon::Cookie::content_type = sub {(-type=>'application/xml')};" 
  } 

  $self->render_screen(xml          => $rss->as_string,
		       screen_title => "Changes in the $label:",
		       rss_icon     => $self->config->rss_icon,
		      );

}

1;

__DATA__

=head1 NAME 

Kwiki::RecentChangesRSS - Kwiki RSS Plugin

=head1 SYNOPSIS

Provides an RSS 2.0 feed of your recent changes.

=head1 REQUIRES

   Kwiki 0.31
   XML::RSS

=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

   cd ~/where/your/kwiki/is/located
   vi plugins

Add this line to the plugins file:

   Kwiki::RecentChangesRSS

   kwiki -update

Then glance over the settings in config/rss.yaml and the documentation
below.  Add your settings to config.yaml.

=head1 CONFIGURATION

In config.yaml, following are necessary for proper functioning:

=over

=item rss_depth

The number of days you go back in time for recent changes.  Defaults to 7 days.

=item rss_icon

URL to an rss icon for the toolbar.  If not provided, you'll see the E<lt>IMG ALTE<gt> text of 'rss'.

=back

The E<lt>channelE<gt> block of the feed requires the following elements to be defined:

=over

=item rss_title

The title of your website.

=item rss_link

The URL of the site this feed applies to. 

=item rss_description

Short descriptive text describing this feed or website.

=back

The following are optional for RSS 2.0:

=over

=item rss_language

An RFC 1766 language code, such as en-US.

=item rss_rating

A PICS rating, if necessary.  See http://www.w3.org/PICS/.

=item rss_copyright

Your copyright line.

=item rss_docs

The URL to a document describing the RSS 2.0 protocol, currently: http://blogs.law.harvard.edu/tech/rss

=item rss_managingEditor

Email address of the person responsible for the editorial content.

=item rss_webMaster

Email address of the person responsible for technical issues regarding the RSS feed.

=item rss_category

A category designation for this feed.  Can be any short text or word.

=item rss_generator

A string indicating what program generated this feed. Currently 'Kwiki::RecentChangesRSS/XML::RSS'.

=item rss_cloud

Not implemented.  Specifies a HTTP-POST, XML-RPC or SOAP interface to get notification of updates to this feed.

=item rss_ttl

Not implemented.  Specifies a time to live value in minutes to determine how long you should cache this feed before updating.

=item rss_image

URL of a GIF, JPEG or PNG image to be displayed with the channel.

=item rss_rating

Not implemented. The PICS rating for the wiki.

=item rss_textInput

Not implemented.  Allows you to define a simple form for input.

=item rss_skipHours

Not implemented.  Speficies the hours in which this feed should not be used.

=item rss_skipDays

Not implemented.  Speficies the days of the week in which this feed should not be used.

=back

=head1 ACKNOWLEDGEMENTS

This is a modified version of Kwiki::RecentChanges by Brian Ingerson.

=head1 AUTHOR

James Peregrino, C<< <jperegrino@post.harvard.edu> >>

=head1 COPYRIGHT

Copyright (c) 2004. James Peregrino. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/rss.yaml__
rss_title: a title goes here
rss_description: a short description goes here
rss_link: a URL goes here
rss_docs: http://blogs.law.harvard.edu/tech/rss
rss_generator: Kwiki::RecentChangesRSS/XML::RSS 0.02
rss_depth: 7
rss_language: en-US
rss_copyright:
rss_managingEditor:
rss_webMaster:
rss_category:
rss_cloud:
rss_ttl:
rss_image:
rss_rating:
rss_textInput:
rss_skipHours:
rss_skipDays:
rss_icon:
__template/tt2/rss_button.html__
<!-- BEGIN rss_button.html -->
<a href="[% script_name %]?action=RecentChangesRSS" accesskey="c" title="RSS">
[% INCLUDE rss_button_icon.html %]
</a>
<!-- END rss_button.html -->
__template/tt2/rss_button_icon.html__
<!-- BEGIN rss_button_icon.html -->
<img src="[% rss_icon %]" alt="rss" >
<!-- END rss_button_icon.html -->
__template/tt2/rss_screen.xml__
[% xml %]
