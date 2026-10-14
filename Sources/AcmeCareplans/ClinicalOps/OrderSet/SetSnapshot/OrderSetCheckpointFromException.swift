import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolExceptionsForCheckpoint(_ items: [CareProtocolException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOrderSetCheckpointsFromException(_ items: [CareProtocolException]) -> [OrderSetCheckpoint] {
        var out: [OrderSetCheckpoint] = []
        for item in items {
            let derived = newOrderSetCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectOrderSetCheckpoint(_ item: OrderSetCheckpoint) -> String {
        return defaultCareProtocolRecordBucket(item.effectiveValue())
    }
}
