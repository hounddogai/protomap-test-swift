import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredOutreachSegmentsForEstimate(_ items: [TieredOutreachSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveDefaultCareGapEstimatesFromSegment(_ items: [TieredOutreachSegment]) -> [DefaultCareGapEstimate] {
        var out: [DefaultCareGapEstimate] = []
        for item in items {
            let derived = newDefaultCareGapEstimate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultCareGapEstimate(_ item: DefaultCareGapEstimate) -> String {
        return classifyAdaptiveOutreachCycle(item.adjustedVolume())
    }
}
