import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistCheckpointsForQuota(_ items: [WorklistCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePriorityQuotasFromCheckpoint(_ items: [WorklistCheckpoint]) -> [PriorityQuota] {
        var out: [PriorityQuota] = []
        for item in items {
            let derived = newPriorityQuota(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocatePriorityQuota(_ item: PriorityQuota) -> Double {
        return worklistManifestWeight(5, active: true)
    }
}
