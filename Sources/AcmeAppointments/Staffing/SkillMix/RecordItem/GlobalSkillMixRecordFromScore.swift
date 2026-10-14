import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultShiftScoresForRecord(_ items: [DefaultShiftScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalSkillMixRecordsFromScore(_ items: [DefaultShiftScore]) -> [GlobalSkillMixRecord] {
        var out: [GlobalSkillMixRecord] = []
        for item in items {
            let derived = newGlobalSkillMixRecord(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchGlobalSkillMixRecord(_ item: GlobalSkillMixRecord) -> String {
        return classifyShiftBatch(item.projectedExposure())
    }
}
