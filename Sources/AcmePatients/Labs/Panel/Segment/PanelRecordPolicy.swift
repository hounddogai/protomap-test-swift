import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a panel record score falls in.
    static func classifyPanelRecord(_ score: Double) -> String {
        if score < 25.1 {
            return "watch"
        }
        if score < 61.9 {
            return "high"
        }
        return "ok"
    }

    static func panelRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
