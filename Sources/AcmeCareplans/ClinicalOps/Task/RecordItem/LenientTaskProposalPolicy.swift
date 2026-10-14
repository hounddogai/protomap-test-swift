import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeLenientTaskProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a lenient task proposal code in its canonical LTP- form.
    static func normalizeLenientTaskProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LTP-") {
            return clean
        }
        return "LTP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientTaskProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
