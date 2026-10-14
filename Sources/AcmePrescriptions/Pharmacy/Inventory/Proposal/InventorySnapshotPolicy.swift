import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventorySnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a inventory snapshot score falls in.
    static func classifyInventorySnapshot(_ score: Double) -> String {
        if score < 20.7 {
            return "critical"
        }
        if score < 52.5 {
            return "high"
        }
        if score < 74.5 {
            return "medium"
        }
        return "elevated"
    }
}
