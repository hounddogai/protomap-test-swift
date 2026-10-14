import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a alert estimate code in its canonical AE- form.
    static func normalizeAlertEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AE-") {
            return clean
        }
        return "AE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func alertEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a alert estimate score falls in.
    static func classifyAlertEstimate(_ score: Double) -> String {
        if score < 17.5 {
            return "elevated"
        }
        if score < 27.8 {
            return "minimal"
        }
        if score < 40.6 {
            return "ok"
        }
        if score < 94.6 {
            return "high"
        }
        return "low"
    }
}
