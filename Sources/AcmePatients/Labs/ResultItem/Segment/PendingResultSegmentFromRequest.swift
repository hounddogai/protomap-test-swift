import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredResultRequestsForSegment(_ items: [TieredResultRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePendingResultSegmentsFromRequest(_ items: [TieredResultRequest]) -> [PendingResultSegment] {
        var out: [PendingResultSegment] = []
        for item in items {
            let derived = newPendingResultSegment(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizePendingResultSegment(_ item: PendingResultSegment) -> String {
        return tieredResultRequestBucket(item.weightedTotal())
    }
}
