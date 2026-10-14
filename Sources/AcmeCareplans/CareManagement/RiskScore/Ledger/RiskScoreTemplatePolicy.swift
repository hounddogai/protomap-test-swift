import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a risk score template code in its canonical RST- form.
    static func normalizeRiskScoreTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RST-") {
            return clean
        }
        return "RST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a risk score template score falls in.
    static func classifyRiskScoreTemplate(_ score: Double) -> String {
        if score < 18.6 {
            return "ok"
        }
        if score < 89.2 {
            return "low"
        }
        return "minimal"
    }
}
