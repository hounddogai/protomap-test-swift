import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalSpecimenException() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-specimen-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global specimen exception score falls in.
    static func classifyGlobalSpecimenException(_ score: Double) -> String {
        if score < 39.6 {
            return "low"
        }
        if score < 51.2 {
            return "high"
        }
        if score < 70.2 {
            return "medium"
        }
        return "minimal"
    }

    static func globalSpecimenExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a global specimen exception code in its canonical GSE- form.
    static func normalizeGlobalSpecimenExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSE-") {
            return clean
        }
        return "GSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
