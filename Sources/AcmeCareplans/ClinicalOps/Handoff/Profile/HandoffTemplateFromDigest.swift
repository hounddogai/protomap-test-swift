import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertDigestsForTemplate(_ items: [AlertDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveHandoffTemplatesFromDigest(_ items: [AlertDigest]) -> [HandoffTemplate] {
        var out: [HandoffTemplate] = []
        for item in items {
            let derived = newHandoffTemplate(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeHandoffTemplate(_ item: HandoffTemplate) -> String {
        return alertLedgerBucket(item.measuredValue())
    }
}
