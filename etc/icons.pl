#!/usr/bin/perl

#
# Create various iphone/app icons from large source image.
# Uses ImageMagick's "convert" utility.
#
# W. Cochran wcochran@vancouver.wsu.edu 2/5/2015
#

use strict;

die "usage: <image> <iconname>\n" unless @ARGV == 2;

my $SRCIMAGE = $ARGV[0];
my $BASE = $ARGV[1];

die "No source image named \"$SRCIMAGE\"\n" unless -f $SRCIMAGE;

my %iconflavors = (
    "iphone-settings" => {"sz" => 29,
			  "scales" => [2, 3]},
    "iphone-spotlight" => {"sz" => 40,
			   "scales" => [2, 3]},
    "iphone-app" => {"sz" => 60,
		     "scales" => [2, 3]},
    "ipad-settings" => {"sz" => 29,
			"scales" => [1, 2]},
    "ipad-spotlight" => {"sz" => 40,
			 "scales" => [1, 2]},
    "ipad-app" => {"sz" => 76,
		     "scales" => [1, 2]},
    "ipad-pro-app" => {"sz" => 83.5,
		     "scales" => [2]},
    "car-play" => {"sz" => 120,
		   "scales" => [1]}
    );

for my $flavor (keys %iconflavors) {
    my $info = $iconflavors{$flavor};
    my $sz = $info->{sz};
    my $scales = $info->{scales};
    for my $scale (@{$scales}) {
	my $size = $sz*$scale;
	my $name = "$BASE-$flavor-$sz-${scale}";
	my $cmd = "convert $SRCIMAGE -resize ${size}x${size} $name.png";
	print "$cmd\n";
	system($cmd) == 0 or die "$!\n";
    }
}
