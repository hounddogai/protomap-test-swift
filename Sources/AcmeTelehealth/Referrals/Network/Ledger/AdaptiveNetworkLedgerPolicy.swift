import AcmePlatform
import Foundation

extension Referrals {
    static func adaptiveNetworkLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func adaptiveNetworkLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func adaptiveNetworkLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
