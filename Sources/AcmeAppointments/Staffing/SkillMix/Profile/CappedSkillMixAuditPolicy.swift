import AcmePlatform
import Foundation

extension Staffing {
    static func cappedSkillMixAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a capped skill mix audit score falls in.
    static func classifyCappedSkillMixAudit(_ score: Double) -> String {
        if score < 72.1 {
            return "low"
        }
        if score < 88.3 {
            return "elevated"
        }
        return "critical"
    }
}
