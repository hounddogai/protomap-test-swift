import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationNoticesForSlot(_ items: [IsolationNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveWeightedTransferSlotsFromNotice(_ items: [IsolationNotice]) -> [WeightedTransferSlot] {
        var out: [WeightedTransferSlot] = []
        for item in items {
            let derived = newWeightedTransferSlot(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedTransferSlot(_ item: WeightedTransferSlot) -> String {
        return classifyIsolationEstimate(item.measuredValue())
    }
}
