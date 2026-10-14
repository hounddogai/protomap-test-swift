import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a manual acuity plan proposal code in its canonical MAPP- form.
    static func normalizeManualAcuityPlanProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MAPP-") {
            return clean
        }
        return "MAPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeManualAcuityPlanProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualAcuityPlanProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
