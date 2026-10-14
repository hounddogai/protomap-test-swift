import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryTaskClaimsForSummary(_ items: [PrimaryTaskClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveHandoffSummariesFromClaim(_ items: [PrimaryTaskClaim]) -> [HandoffSummary] {
        var out: [HandoffSummary] = []
        for item in items {
            let derived = newHandoffSummary(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyHandoffSummary(_ item: HandoffSummary) -> String {
        return classifyAdaptiveTaskManifest(item.adjustedValue())
    }
}
