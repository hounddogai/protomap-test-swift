import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeGlobalIsolationRequestsForEstimate(_ items: [GlobalIsolationRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBedBoardEstimatesFromRequest(_ items: [GlobalIsolationRequest]) -> [BedBoardEstimate] {
        var out: [BedBoardEstimate] = []
        for item in items {
            let derived = newBedBoardEstimate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateBedBoardEstimate(_ item: BedBoardEstimate) -> String {
        return classifyBatchedIsolationWindow(item.adjustedTotal())
    }
}
