//
//  TranslatedStrings.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 27/09/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import Foundation

/// Provides translated strings for the Ver-ID UI
/// - Since: 1.8.0
@objc public class TranslatedStrings: NSObject, XMLParserDelegate {
    
    private var translations: [String:String] = [:]
    private var chars: String = ""
    private var translation: String = ""
    private var original: String = ""
    /// Language to which the strings are translated
    @objc private(set) public var resolvedLanguage: String = "en"
    /// Geographic region used in translation
    @objc private(set) public var resolvedRegion: String?
    
    /// Constructor
    /// - Parameter useCurrentLocale: If set to `false` strings will not be translated. Otherwise the class will attempt to find the best matching available translation, first looking in the app's main bundle, then in the VerIDUI bundle.
    @objc public init(useCurrentLocale: Bool = true) {
        super.init()
        if useCurrentLocale {
            let lang = Locale.current.languageCode ?? "en"
            for bundle in [Bundle.main, Bundle(for: type(of: self))] {
                if let url = self.translationURLFromBundle(bundle, language: lang, region: Locale.current.regionCode), let data = try? Data(contentsOf: url) {
                    self.parseData(data)
                    break
                }
            }
        }
    }
    
    /// Constructor
    /// - Parameter url: URL of the file that contains the translation
    @objc public init(url: URL) throws {
        super.init()
        let data = try Data(contentsOf: url)
        self.parseData(data)
    }
    
    /// Get a string translation
    @objc public subscript(original: String, args: CVarArg...) -> String {
        get {
            let translation = self.translations[original] ?? original
            if translation.isEmpty {
                return original
            }
            switch args.count {
            case 1:
                return String(format: translation, args[0])
            case 2:
                return String(format: translation, args[0], args[1])
            case 3:
                return String(format: translation, args[0], args[1], args[2])
            case 4:
                return String(format: translation, args[0], args[1], args[2], args[3])
            case 5:
                return String(format: translation, args[0], args[1], args[2], args[3], args[4])
            case 6:
                return String(format: translation, args[0], args[1], args[2], args[3], args[4], args[5])
            case 7:
                return String(format: translation, args[0], args[1], args[2], args[3], args[4], args[5], args[6])
            case 8:
                return String(format: translation, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
            default:
                return translation
            }
        }
    }
    
    /// Get a translation for a given string
    /// - Parameter original: String to be translated
    /// - Parameter args: Arguments for string formatter
    /// - Returns: Translated string or the original if a translation for the original is unavailable
    public func translation(for original: String, args: CVarArg...) -> String {
        return self[original, args]
    }
    
    /// Indicates whether a translation for the given string is available
    /// - Parameter original: String for which to find the translation
    @objc public func isTranslated(_ original: String) -> Bool {
        if let translation = self.translations[original], !translation.isEmpty {
            return true
        }
        return false
    }
    
    func parseData(_ data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    func translationURLFromBundle(_ bundle: Bundle, language: String, region: String?) -> URL? {
        if let r = region, let url = bundle.url(forResource: "\(language)_\(r)", withExtension: "xml") {
            return url
        } else if let url = bundle.url(forResource: language, withExtension: "xml") {
            return url
        } else if let url = (try? FileManager.default.contentsOfDirectory(at: bundle.bundleURL, includingPropertiesForKeys: nil, options: []))?.first(where: { $0.lastPathComponent.starts(with: language+"_") && $0.pathExtension == "xml" }) {
            return url
        }
        return nil
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "strings", let language = attributeDict["language"] {
            self.resolvedLanguage = language
            self.resolvedRegion = attributeDict["region"]
            return
        }
        if elementName == "string" {
            original = ""
            translation = ""
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        chars.append(string)
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "original" {
            original = self.chars.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "translation" {
            translation = self.chars.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "string" {
            translations[original] = translation
        }
        self.chars = ""
    }
}
