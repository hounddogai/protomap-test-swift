import AcmePlatform
import Foundation

extension Imaging {
    static func lenientCareProtocolClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a lenient care protocol claim code in its canonical LCPC- form.
    static func normalizeLenientCareProtocolClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCPC-") {
            return clean
        }
        return "LCPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient care protocol claim score falls in.
    static func classifyLenientCareProtocolClaim(_ score: Double) -> String {
        if score < 12.5 {
            return "minimal"
        }
        if score < 96.5 {
            return "critical"
        }
        return "low"
    }

    static func lenientCareProtocolClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
