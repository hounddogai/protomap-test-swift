import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set snapshot code in its canonical OSS- form.
    static func normalizeOrderSetSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSS-") {
            return clean
        }
        return "OSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeOrderSetSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
