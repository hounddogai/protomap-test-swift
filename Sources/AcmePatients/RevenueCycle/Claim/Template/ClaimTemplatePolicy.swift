import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a claim template score falls in.
    static func classifyClaimTemplate(_ score: Double) -> String {
        if score < 31.1 {
            return "medium"
        }
        if score < 32.3 {
            return "ok"
        }
        if score < 52.2 {
            return "minimal"
        }
        return "high"
    }

    static func claimTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
