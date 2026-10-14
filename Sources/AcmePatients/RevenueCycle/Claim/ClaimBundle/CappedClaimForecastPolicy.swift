import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a capped claim forecast code in its canonical CCF- form.
    static func normalizeCappedClaimForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCF-") {
            return clean
        }
        return "CCF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedClaimForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-claim-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
