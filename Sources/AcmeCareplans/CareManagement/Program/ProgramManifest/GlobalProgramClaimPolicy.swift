import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a global program claim code in its canonical GPC- form.
    static func normalizeGlobalProgramClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPC-") {
            return clean
        }
        return "GPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalProgramClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
