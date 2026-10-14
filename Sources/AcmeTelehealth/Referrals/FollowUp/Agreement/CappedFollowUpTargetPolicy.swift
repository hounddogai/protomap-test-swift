import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedFollowUpTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-follow-up-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped follow up target code in its canonical CFUT- form.
    static func normalizeCappedFollowUpTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFUT-") {
            return clean
        }
        return "CFUT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedFollowUpTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
