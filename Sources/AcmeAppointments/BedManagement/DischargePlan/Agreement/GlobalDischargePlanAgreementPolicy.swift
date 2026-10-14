import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalDischargePlanAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-discharge-plan-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a global discharge plan agreement code in its canonical GDPA- form.
    static func normalizeGlobalDischargePlanAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDPA-") {
            return clean
        }
        return "GDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalDischargePlanAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
