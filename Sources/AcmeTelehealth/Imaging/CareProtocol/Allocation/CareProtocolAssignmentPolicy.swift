import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol assignment code in its canonical CPA- form.
    static func normalizeCareProtocolAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPA-") {
            return clean
        }
        return "CPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCareProtocolAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
