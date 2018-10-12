//
//  PageParser.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation

struct PageParser: Parser {
    typealias Model = Page
    
    func parse(bundle: Bundle) -> [Page]? {
        var jsonFileURLsInOtherBundles: [URL] = []
        
        // Search for user-defined page defintions
        for aBundle in Bundle.allBundles where aBundle != bundle {
            if let jsonFileURLs = urlsForFilesInBundle(aBundle, with: .screen) {
                jsonFileURLsInOtherBundles.append(contentsOf: jsonFileURLs)
            }
        }
        return jsonFileURLsInOtherBundles.compactMap({ pageFromJSONFile(url: $0) })
    }
    
}

// Private API
private extension PageParser {
    
    /// Produces a Page model object from the JSON file at the specified URL.
    func pageFromJSONFile(url: URL) -> Page? {
        guard let pageDict = pageDictFromJSONFile(url: url) else {
            return nil
        }
        var elementMapping: [SupportedElementType: [String: String]] = [:]
        let pageName: String = pageDict["name"] as? String ?? fileNameWithoutJSONExt(fileURL: url)
        SupportedElementType.allCases.forEach({ elementType in
            elementMapping[elementType] = elementMap(pageDict: pageDict, element: elementType)
        })
        return Page(name: pageName, elements: elementMapping)
    }
    
    /// Retrieves file URLs for files in the specified bundle and fil extension.
    func urlsForFilesInBundle(_ bundle: Bundle, with extension: FileExtension) -> [URL]? {
        if let fileURLs = bundle.urls(forResourcesWithExtension: "\(`extension`)", subdirectory: nil) {
            return fileURLs
        }
        return nil
    }
    
    private func pageDictFromJSONFile(url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url, options: []) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        return json as? [String: Any]
    }
    
    private func elementMap(pageDict: [String: Any], element: SupportedElementType) -> [String: String] {
        return pageDict[element.description] as? [String: String] ?? [:]
    }
    
    private func fileNameWithoutJSONExt(fileURL: URL) -> String {
        let fileNameWithExtension = fileURL.lastPathComponent
        return fileNameWithExtension.replacingOccurrences(of: ".\(FileExtension.json)", with: "")
    }

}
