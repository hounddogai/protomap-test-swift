import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a charge agreement score falls in.
    static func classifyChargeAgreement(_ score: Double) -> String {
        if score < 6.6 {
            return "critical"
        }
        if score < 10.0 {
            return "low"
        }
        if score < 40.1 {
            return "high"
        }
        if score < 70.2 {
            return "minimal"
        }
        return "ok"
    }

    static func chargeAgreementSpan(_ start: Int, end: Int) -> Int {
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
