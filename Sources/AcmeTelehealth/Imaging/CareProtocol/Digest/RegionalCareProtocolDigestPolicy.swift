import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 32489.0, in order.
    static func regionalCareProtocolDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32489.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalCareProtocolDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalCareProtocolDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-care-protocol-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional care protocol digest code in its canonical RCPD- form.
    static func normalizeRegionalCareProtocolDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCPD-") {
            return clean
        }
        return "RCPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
