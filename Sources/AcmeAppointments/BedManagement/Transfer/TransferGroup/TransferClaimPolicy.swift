import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer claim score falls in.
    static func classifyTransferClaim(_ score: Double) -> String {
        if score < 4.1 {
            return "high"
        }
        if score < 59.9 {
            return "minimal"
        }
        if score < 77.7 {
            return "watch"
        }
        return "low"
    }

    static func transferClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func transferClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
