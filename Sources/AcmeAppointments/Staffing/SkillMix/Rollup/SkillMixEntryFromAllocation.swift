import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryShiftAllocationsForEntry(_ items: [PrimaryShiftAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveSkillMixEntriesFromAllocation(_ items: [PrimaryShiftAllocation]) -> [SkillMixEntry] {
        var out: [SkillMixEntry] = []
        for item in items {
            let derived = newSkillMixEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileSkillMixEntry(_ item: SkillMixEntry) -> String {
        return rollingShiftManifestBucket(item.adjustedTotal())
    }
}
