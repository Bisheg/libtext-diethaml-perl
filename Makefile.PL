use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Diethaml',
    AUTHOR              => 'MIZUTANI Tociyuki <tociyuki@gmail.com>',
    VERSION_FROM        => 'lib/Text/Diethaml.pm',
    ABSTRACT_FROM       => 'lib/Text/Diethaml.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
