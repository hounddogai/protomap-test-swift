import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a strict rounding proposal score falls in.
    static func classifyStrictRoundingProposal(_ score: Double) -> String {
        if score < 15.9 {
            return "critical"
        }
        if score < 34.5 {
            return "medium"
        }
        if score < 62.6 {
            return "minimal"
        }
        if score < 72.8 {
            return "watch"
        }
        return "elevated"
    }

    /// Puts a strict rounding proposal code in its canonical SRP- form.
    static func normalizeStrictRoundingProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRP-") {
            return clean
        }
        return "SRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictRoundingProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
