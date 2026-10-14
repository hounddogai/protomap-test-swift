import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan estimate code in its canonical DPE- form.
    static func normalizeDischargePlanEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPE-") {
            return clean
        }
        return "DPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDischargePlanEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dischargePlanEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
