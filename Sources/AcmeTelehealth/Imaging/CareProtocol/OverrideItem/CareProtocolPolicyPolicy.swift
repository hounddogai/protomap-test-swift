import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol policy code in its canonical CPP- form.
    static func normalizeCareProtocolPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPP-") {
            return clean
        }
        return "CPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCareProtocolPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
