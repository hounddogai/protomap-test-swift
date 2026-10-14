import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a fallback care protocol mapping code in its canonical FCPM- form.
    static func normalizeFallbackCareProtocolMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCPM-") {
            return clean
        }
        return "FCPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCareProtocolMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-care-protocol-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback care protocol mapping score falls in.
    static func classifyFallbackCareProtocolMapping(_ score: Double) -> String {
        if score < 17.6 {
            return "elevated"
        }
        if score < 69.6 {
            return "ok"
        }
        if score < 78.8 {
            return "critical"
        }
        if score < 91.4 {
            return "minimal"
        }
        return "high"
    }

    static func fallbackCareProtocolMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
