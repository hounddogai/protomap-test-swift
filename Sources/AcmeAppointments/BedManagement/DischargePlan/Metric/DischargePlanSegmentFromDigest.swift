import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardDigestsForSegment(_ items: [BedBoardDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveDischargePlanSegmentsFromDigest(_ items: [BedBoardDigest]) -> [DischargePlanSegment] {
        var out: [DischargePlanSegment] = []
        for item in items {
            let derived = newDischargePlanSegment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeDischargePlanSegment(_ item: DischargePlanSegment) -> Double {
        return bedBoardDigestWeight(5, active: true)
    }
}
