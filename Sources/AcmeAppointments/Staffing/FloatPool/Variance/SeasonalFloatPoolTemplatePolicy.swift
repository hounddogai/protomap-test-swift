import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a seasonal float pool template code in its canonical SFPT- form.
    static func normalizeSeasonalFloatPoolTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFPT-") {
            return clean
        }
        return "SFPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalFloatPoolTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-float-pool-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalFloatPoolTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeSeasonalFloatPoolTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
