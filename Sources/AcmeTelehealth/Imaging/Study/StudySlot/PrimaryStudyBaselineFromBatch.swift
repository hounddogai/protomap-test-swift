import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalCareProtocolBatchesForBaseline(_ items: [GlobalCareProtocolBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePrimaryStudyBaselinesFromBatch(_ items: [GlobalCareProtocolBatch]) -> [PrimaryStudyBaseline] {
        var out: [PrimaryStudyBaseline] = []
        for item in items {
            let derived = newPrimaryStudyBaseline(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePrimaryStudyBaseline(_ item: PrimaryStudyBaseline) -> String {
        return primaryCareProtocolMappingBucket(item.effectiveExposure())
    }
}
