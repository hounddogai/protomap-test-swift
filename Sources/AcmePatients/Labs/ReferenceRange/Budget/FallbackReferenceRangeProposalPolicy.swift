import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback reference range proposal code in its canonical FRRP- form.
    static func normalizeFallbackReferenceRangeProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRRP-") {
            return clean
        }
        return "FRRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback reference range proposal score falls in.
    static func classifyFallbackReferenceRangeProposal(_ score: Double) -> String {
        if score < 5.1 {
            return "watch"
        }
        if score < 25.0 {
            return "high"
        }
        if score < 53.6 {
            return "ok"
        }
        if score < 57.4 {
            return "minimal"
        }
        return "low"
    }

    static func fallbackReferenceRangeProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackReferenceRangeProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-reference-range-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
