import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a inventory audit score falls in.
    static func classifyInventoryAudit(_ score: Double) -> String {
        if score < 46.4 {
            return "ok"
        }
        if score < 57.6 {
            return "low"
        }
        if score < 71.3 {
            return "medium"
        }
        return "high"
    }

    static func inventoryAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
