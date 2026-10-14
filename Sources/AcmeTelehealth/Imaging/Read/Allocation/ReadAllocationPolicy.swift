import AcmePlatform
import Foundation

extension Imaging {
    static func readAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a read allocation score falls in.
    static func classifyReadAllocation(_ score: Double) -> String {
        if score < 55.8 {
            return "medium"
        }
        if score < 57.3 {
            return "elevated"
        }
        if score < 63.7 {
            return "high"
        }
        return "ok"
    }
}
