import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a panel estimate score falls in.
    static func classifyPanelEstimate(_ score: Double) -> String {
        if score < 20.3 {
            return "high"
        }
        if score < 24.0 {
            return "critical"
        }
        if score < 54.9 {
            return "elevated"
        }
        if score < 75.8 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a panel estimate code in its canonical PE- form.
    static func normalizePanelEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PE-") {
            return clean
        }
        return "PE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
