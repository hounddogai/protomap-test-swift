import AcmePlatform
import Foundation

extension BedManagement {
    static func transferBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func transferBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a transfer bundle score falls in.
    static func classifyTransferBundle(_ score: Double) -> String {
        if score < 36.7 {
            return "elevated"
        }
        if score < 40.4 {
            return "watch"
        }
        return "medium"
    }
}
