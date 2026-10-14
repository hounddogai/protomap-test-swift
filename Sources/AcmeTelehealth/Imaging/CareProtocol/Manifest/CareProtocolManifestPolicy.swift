import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 42489.0, in order.
    static func careProtocolManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42489.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func careProtocolManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func careProtocolManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
