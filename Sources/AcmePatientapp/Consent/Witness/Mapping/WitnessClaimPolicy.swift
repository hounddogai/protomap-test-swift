import AcmePlatform
import Foundation

extension Consent {
    static func witnessClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func witnessClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
