import AcmePlatform
import Foundation

extension Imaging {
    static func modalityLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func modalityLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
