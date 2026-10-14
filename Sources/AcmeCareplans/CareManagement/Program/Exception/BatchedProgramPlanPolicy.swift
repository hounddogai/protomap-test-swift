import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a batched program plan code in its canonical BPP- form.
    static func normalizeBatchedProgramPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BPP-") {
            return clean
        }
        return "BPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedProgramPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
