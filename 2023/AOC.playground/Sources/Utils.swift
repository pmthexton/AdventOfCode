import Foundation
import XCTest

public class Utils {
    public static func loadLines(file: String) -> [String]? {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt") else {
            return nil
        }
        let data = try! String(contentsOf: url)
        var lines = data.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map { String($0) }
        // Xcode playgrounds insists on putting an empty line at the end of txt
        // files even when you try to remove it
        if let ln = lines.last,
           ln.isEmpty {
            _ = lines.removeLast()
        }
        return lines
    }
}
