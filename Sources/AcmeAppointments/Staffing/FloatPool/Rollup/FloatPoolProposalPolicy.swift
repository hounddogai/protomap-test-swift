import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a float pool proposal score falls in.
    static func classifyFloatPoolProposal(_ score: Double) -> String {
        if score < 26.0 {
            return "ok"
        }
        if score < 34.4 {
            return "critical"
        }
        if score < 65.6 {
            return "elevated"
        }
        return "low"
    }

    static func floatPoolProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a float pool proposal code in its canonical FPP- form.
    static func normalizeFloatPoolProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPP-") {
            return clean
        }
        return "FPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
