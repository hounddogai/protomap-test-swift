import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingCareProtocolVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-care-protocol-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 11146.0, in order.
    static func pendingCareProtocolVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11146.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingCareProtocolVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a pending care protocol variance code in its canonical PCPV- form.
    static func normalizePendingCareProtocolVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCPV-") {
            return clean
        }
        return "PCPV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
