import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a dispense plan code in its canonical DP- form.
    static func normalizeDispensePlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DP-") {
            return clean
        }
        return "DP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDispensePlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispensePlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
