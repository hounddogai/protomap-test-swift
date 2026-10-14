import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy ledger score falls in.
    static func classifyProxyLedger(_ score: Double) -> String {
        if score < 42.9 {
            return "watch"
        }
        if score < 53.8 {
            return "elevated"
        }
        if score < 59.6 {
            return "minimal"
        }
        if score < 99.2 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 72355.0, in order.
    static func proxyLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72355.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a proxy ledger code in its canonical PL- form.
    static func normalizeProxyLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PL-") {
            return clean
        }
        return "PL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
