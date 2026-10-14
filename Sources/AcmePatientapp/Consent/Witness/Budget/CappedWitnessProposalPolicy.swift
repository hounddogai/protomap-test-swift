import AcmePlatform
import Foundation

extension Consent {
    /// Puts a capped witness proposal code in its canonical CWP- form.
    static func normalizeCappedWitnessProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CWP-") {
            return clean
        }
        return "CWP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedWitnessProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func cappedWitnessProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
