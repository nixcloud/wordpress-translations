# what is this?
to package wordpress languages files i needed a mirror (cache) which would let me download a certain version reliably.
wordpress uses SVN for themes and plugins but not for the languages thus this mirror converts the language downloads
into a GIT repository.

# how is this used?

this is an example of how i'm using it with the nix programming language on nixos:

    supportedLanguages = {
      en_GB = { revision="d6c005372a5318fd758b710b77a800c86518be13"; sha256="0qbbsi87k47q4rgczxx541xz4z4f4fr49hw4lnaxkdsf5maz8p9p"; };
      de_DE = { revision="3c62955c27baaae98fd99feb35593d46562f4736"; sha256="1shndgd11dk836dakrjlg2arwv08vqx6j4xjh4jshvwmjab6ng6p"; };
      zh_ZN = { revision="12b9f811e8cae4b6ee41de343d35deb0a8fdda6d"; sha256="1339ggsxh0g6lab37jmfxicsax4h702rc3fsvv5azs7mcznvwh47"; };
      fr_FR = { revision="688c8b1543e3d38d9e8f57e0a6f2a2c3c8b588bd"; sha256="1j41iak0i6k7a4wzyav0yrllkdjjskvs45w53db8vfm8phq1n014"; };
    };
  
    downloadLanguagePack = language: revision: sha256s:
      pkgs.stdenv.mkDerivation rec {
        name = "wp_${language}";
        src = pkgs.fetchFromGitHub {
          owner = "nixcloud";
          repo = "wordpress-translations";
          rev = revision;
          sha256 = sha256s;
        };
        installPhase = "mkdir -p $out; cp -R * $out/";
      };
  
    selectedLanguages = map (lang: downloadLanguagePack lang supportedLanguages.${lang}.revision supportedLanguages.${lang}.sha256) (config.languages);

in essence: based on a GIT revision this gives us reproducible downloads in comparison to the wordpress portal (3.7.2015).

# versioning

WP upstream seems to be using x.y versioning for the languages, this is why this repo has branches like this:

    ...
    tr_TR-4.0
    tr_TR-4.1
    tr_TR-4.2
    tr_TR-4.3
    tr_TR-4.4
    ug_CN-4.1
    ug_CN-4.2
    ug_CN-4.3
    ug_CN-4.4
    uk-4.2
    uk-4.3
    uk-4.4
    vi-4.3
    vi-4.4
    zh_CN-4.0
    zh_CN-4.1
    zh_CN-4.2
    zh_CN-4.3
    zh_CN-4.4
    zh_TW-4.0
    zh_TW-4.1
    zh_TW-4.2
    zh_TW-4.3
    zh_TW-4.4

zh_TW-4.4 should contain the latest zh_TW locales after running ./udpate! 

use:

    git branch -l

and inside the branch use:

    git log 

to find the respective hash which needs to be filled, from the example above,  a attribute called revision=...

# who

contact js@lastlog.de for inquiries
