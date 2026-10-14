import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardDigestsForSegmentSegment(_ items: [BedBoardDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveIsolationSegmentsFromDigest(_ items: [BedBoardDigest]) -> [IsolationSegment] {
        var out: [IsolationSegment] = []
        for item in items {
            let derived = newIsolationSegment(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveIsolationSegment(_ item: IsolationSegment) -> String {
        return bedBoardForecastBucket(item.adjustedValue())
    }
}
