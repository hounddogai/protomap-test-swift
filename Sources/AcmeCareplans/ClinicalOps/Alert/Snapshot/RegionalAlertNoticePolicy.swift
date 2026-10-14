import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a regional alert notice code in its canonical RAN- form.
    static func normalizeRegionalAlertNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAN-") {
            return clean
        }
        return "RAN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalAlertNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-alert-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalAlertNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 40690.0, in order.
    static func regionalAlertNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40690.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
