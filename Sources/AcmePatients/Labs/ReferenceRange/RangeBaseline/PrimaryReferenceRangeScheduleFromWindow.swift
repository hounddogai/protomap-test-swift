import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientReferenceRangeWindowsForSchedule(_ items: [LenientReferenceRangeWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePrimaryReferenceRangeSchedulesFromWindow(_ items: [LenientReferenceRangeWindow]) -> [PrimaryReferenceRangeSchedule] {
        var out: [PrimaryReferenceRangeSchedule] = []
        for item in items {
            let derived = newPrimaryReferenceRangeSchedule(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryReferenceRangeSchedule(_ item: PrimaryReferenceRangeSchedule) -> String {
        return regionalReferenceRangeSlotBucket(item.projectedExposure())
    }
}
