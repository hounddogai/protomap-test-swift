import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a statement entry score falls in.
    static func classifyStatementEntry(_ score: Double) -> String {
        if score < 21.2 {
            return "minimal"
        }
        if score < 29.8 {
            return "critical"
        }
        return "elevated"
    }
}
