# Translating Ver-ID UI

As of version 1.8.0 Ver-ID UI allows you to supply language translations for Ver-ID sessions.

The Ver-ID-UI project provides [Python 2.7](https://www.python.org/download/releases/2.7/) scripts to generate an empty translation XML and to verify that a given file is not missing any translations.

## Generating a translation XML

Open Terminal and navigate to the folder containing VerIDUI.xcodeproj. Enter:

~~~shell
cd VerIDUI/Localization
python translation_xml.py
~~~
The command will collect all strings used in the source code and output a string like this:

~~~xml
<?xml version="1.0" encoding="utf-8"?>
<strings language="" region="">
    <string>
        <original>Align your face with the oval</original>
        <translation></translation>
    </string>
    <string>
        <original>Authentication failed</original>
        <translation></translation>
    </string>
    <string>
        <original>Avoid standing in a light that throws sharp shadows like in sharp sunlight or directly under a lamp.</original>
        <translation></translation>
    </string>
    <string>
        <original>Avoid standing in front of busy backgrounds.</original>
        <translation></translation>
    </string>
    <string>
        <original>Camera access denied</original>
        <translation></translation>
    </string>
    <string>
        <original>Cancel</original>
        <translation></translation>
    </string>
    <string>
        <original>Done</original>
        <translation></translation>
    </string>
    <string>
        <original>Failed</original>
        <translation></translation>
    </string>
    <string>
        <original>Great, hold it</original>
        <translation></translation>
    </string>
    <string>
        <original>Great. Session succeeded.</original>
        <translation></translation>
    </string>
    <string>
        <original>Great. You are now registered.</original>
        <translation></translation>
    </string>
    <string>
        <original>Great. You authenticated using your face.</original>
        <translation></translation>
    </string>
    <string>
        <original>Hold it</original>
        <translation></translation>
    </string>
    <string>
        <original>If you can, take off your glasses.</original>
        <translation></translation>
    </string>
    <string>
        <original>OK</original>
        <translation></translation>
    </string>
    <string>
        <original>Please go to settings and enable camera in the settings for %@.</original>
        <translation></translation>
    </string>
    <string>
        <original>Please turn slowly</original>
        <translation></translation>
    </string>
    <string>
        <original>Please wait</original>
        <translation></translation>
    </string>
    <string>
        <original>Preparing face detection</original>
        <translation></translation>
    </string>
    <string>
        <original>Registration failed</original>
        <translation></translation>
    </string>
    <string>
        <original>Resume session</original>
        <translation></translation>
    </string>
    <string>
        <original>Session failed</original>
        <translation></translation>
    </string>
    <string>
        <original>Show tips</original>
        <translation></translation>
    </string>
    <string>
        <original>Slowly turn to follow the arrow</original>
        <translation></translation>
    </string>
    <string>
        <original>Success</original>
        <translation></translation>
    </string>
    <string>
        <original>Tip %d of %d</original>
        <translation></translation>
    </string>
    <string>
        <original>Try again</original>
        <translation></translation>
    </string>
    <string>
        <original>Turn your head in the direction of the arrow</original>
        <translation></translation>
    </string>
    <string>
        <original>Unable to resume</original>
        <translation></translation>
    </string>
    <string>
        <original>You may have turned too far. Only turn in the requested direction until the oval turns green.</original>
        <translation></translation>
    </string>
</strings>
~~~

- Enter the translation of the string inside the `<original>` tag in the `<translation>` tag.
- Fill in the `language` attribute of the root `<strings>` tag with an [ISO 639-1 language code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes). For example, for Frech, replace `language=""` with `language="fr"`.
- Fill in the `region` attribute of the root `<strings>` tag with an [ISO 3166-2 region code](https://en.wikipedia.org/wiki/ISO_3166-2) for the regional language variation. For example, for Canada, replace `region=""` with `region="CA"`. If your translation is region-independent you can delete the region attribute altogether.
- Save the filled out XML file using the pattern `language[_REGION].xml` replacing `language` with the ISO 639-1 code for the language your translation supplies and the optional `REGION` with the region the translation covers. For the purpose of this guide let's say it's a translation to Canadian French and the file is named **fr_CA.xml**. If region is not applicable omit it and the preceding underscore from the file (e.g., **fr.xml**).

## Checking that your translation is complete
Once you translate all the strings in the XML run:

~~~shell
python test_translation.py fr_CA.xml
~~~
If all strings are translated the command will output:

~~~shell
All translated
~~~
Otherwise it will output the text `Missing:` followed by the missing translations, each on one line:

~~~shell
Missing:
Show tips
Slowly turn to follow the arrow
~~~

## Running a Ver-ID session with your translation

There are 2 ways you can use your translation in Ver-ID. You can either bundle it with your app and let Ver-ID choose the appropriate translation based on the device's current locale. Or you can specify it when you create a Ver-ID session.

### Bundling the translation with your app 
Ver-ID will look in the root of your app's main bundle for available translations and use them if they match the device's current locale.

To let Ver-ID automatically choose your translation it's important that your translation file is named using the `language[_REGION].xml` pattern mentioned above and it's placed at the root of your app's main bundle.

Ver-ID uses the following logic to choose the translation if none is specified when constructing the Ver-ID session object:

- If a translation matching the device's current language and region is found in the main bundle it will be used.
- Otherwise, if a translation matching the device language is found in the main bundle it will be used.
- If both of the above fail, Ver-ID will look for a translation whose language matches the device language with a different region. For example, if the device's language is set to French and its region is set to France but there is no translation available named fr_FR.xml or fr.xml but there is fr_CA.xml it will use the latter.
- The above process is repeated using the Ver-ID bundle.
- If no translation is found after that the strings in the Ver-ID session won't be translated and will be shown in English.

### Specifying translation when creating a Ver-ID session
This method allows you to override the system or app locale and use a specific translation. This may be useful, for example, if your app is used on one device by users with multiple language preferences or if you want the translation choice to be based your own locale resolution.

Following on the example above, let's say you added your **fr_CA.xml** file to a folder called **translations** in your app's project. You can start a session that uses your translation like this:

~~~swift
do {
	let verid: VerID // Received from VerIDFactory
	guard let url = Bundle.main.url(forResource: "fr_CA", withExtension: "xml", subdirectory: "translations") else {
		return
	}
	let translation = try TranslatedStrings(url: url)
	let settings = LivenessDetectionSessionSettings()
	let session = VerIDSession(environment: verid, settings: settings, translatedStrings: translation)
	session.delegate = self
	session.start()
} catch {
	// Thrown if the url cannot be read
}
~~~