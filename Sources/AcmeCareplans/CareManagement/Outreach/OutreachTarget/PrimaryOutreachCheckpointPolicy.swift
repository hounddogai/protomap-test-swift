import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePrimaryOutreachCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary outreach checkpoint code in its canonical POC- form.
    static func normalizePrimaryOutreachCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POC-") {
            return clean
        }
        return "POC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
