import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan mapping code in its canonical APM- form.
    static func normalizeAcuityPlanMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APM-") {
            return clean
        }
        return "APM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func acuityPlanMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a acuity plan mapping score falls in.
    static func classifyAcuityPlanMapping(_ score: Double) -> String {
        if score < 14.7 {
            return "medium"
        }
        if score < 16.3 {
            return "high"
        }
        if score < 65.9 {
            return "watch"
        }
        return "minimal"
    }
}
