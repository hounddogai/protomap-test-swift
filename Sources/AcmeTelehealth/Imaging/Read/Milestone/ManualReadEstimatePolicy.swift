import AcmePlatform
import Foundation

extension Imaging {
    static func mergeManualReadEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualReadEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a manual read estimate code in its canonical MRE- form.
    static func normalizeManualReadEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRE-") {
            return clean
        }
        return "MRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
