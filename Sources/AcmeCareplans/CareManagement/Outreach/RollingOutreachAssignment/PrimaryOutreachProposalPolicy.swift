import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryOutreachProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func primaryOutreachProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary outreach proposal code in its canonical POP- form.
    static func normalizePrimaryOutreachProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POP-") {
            return clean
        }
        return "POP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary outreach proposal score falls in.
    static func classifyPrimaryOutreachProposal(_ score: Double) -> String {
        if score < 80.0 {
            return "watch"
        }
        if score < 92.3 {
            return "minimal"
        }
        return "medium"
    }
}
