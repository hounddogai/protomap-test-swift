import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultConsentFormAdjustmentsForBatch(_ items: [DefaultConsentFormAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormBatchesFromAdjustment(_ items: [DefaultConsentFormAdjustment]) -> [ConsentFormBatch] {
        var out: [ConsentFormBatch] = []
        for item in items {
            let derived = newConsentFormBatch(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitConsentFormBatch(_ item: ConsentFormBatch) -> String {
        return consentFormCheckpointBucket(item.netExposure())
    }
}
