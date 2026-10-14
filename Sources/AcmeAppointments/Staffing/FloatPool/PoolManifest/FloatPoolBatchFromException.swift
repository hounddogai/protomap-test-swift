import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanExceptionsForBatch(_ items: [AcuityPlanException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveFloatPoolBatchesFromException(_ items: [AcuityPlanException]) -> [FloatPoolBatch] {
        var out: [FloatPoolBatch] = []
        for item in items {
            let derived = newFloatPoolBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceFloatPoolBatch(_ item: FloatPoolBatch) -> String {
        return acuityPlanExceptionBucket(item.measuredValue())
    }
}
