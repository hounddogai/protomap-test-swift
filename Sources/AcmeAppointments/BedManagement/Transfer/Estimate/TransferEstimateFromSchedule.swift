import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationSchedulesForEstimate(_ items: [IsolationSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveTransferEstimatesFromSchedule(_ items: [IsolationSchedule]) -> [TransferEstimate] {
        var out: [TransferEstimate] = []
        for item in items {
            let derived = newTransferEstimate(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeTransferEstimate(_ item: TransferEstimate) -> Double {
        return isolationRequestWeight(9, active: true)
    }
}
