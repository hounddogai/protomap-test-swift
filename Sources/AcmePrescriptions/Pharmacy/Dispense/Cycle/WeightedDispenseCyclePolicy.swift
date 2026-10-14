import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedDispenseCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-dispense-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted dispense cycle code in its canonical WDC- form.
    static func normalizeWeightedDispenseCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WDC-") {
            return clean
        }
        return "WDC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
