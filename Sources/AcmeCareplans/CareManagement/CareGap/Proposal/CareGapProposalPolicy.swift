import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a care gap proposal code in its canonical CGP- form.
    static func normalizeCareGapProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGP-") {
            return clean
        }
        return "CGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care gap proposal score falls in.
    static func classifyCareGapProposal(_ score: Double) -> String {
        if score < 4.7 {
            return "low"
        }
        if score < 73.6 {
            return "medium"
        }
        if score < 75.2 {
            return "minimal"
        }
        if score < 79.2 {
            return "watch"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
