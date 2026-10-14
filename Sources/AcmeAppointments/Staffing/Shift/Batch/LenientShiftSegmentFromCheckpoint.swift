import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedSkillMixCheckpointsForSegment(_ items: [CappedSkillMixCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientShiftSegmentsFromCheckpoint(_ items: [CappedSkillMixCheckpoint]) -> [LenientShiftSegment] {
        var out: [LenientShiftSegment] = []
        for item in items {
            let derived = newLenientShiftSegment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLenientShiftSegment(_ item: LenientShiftSegment) -> Double {
        return lenientSkillMixAssignmentWeight(2, active: true)
    }
}
