import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionBudgetsForNotice(_ items: [InteractionBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRecallNoticesFromBudget(_ items: [InteractionBudget]) -> [RecallNotice] {
        var out: [RecallNotice] = []
        for item in items {
            let derived = newRecallNotice(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRecallNotice(_ item: RecallNotice) -> String {
        return defaultInteractionMilestoneBucket(item.measuredValue())
    }
}
