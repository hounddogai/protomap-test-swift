import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallSnapshotsForOverride(_ items: [RecallSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInteractionOverridesFromSnapshot(_ items: [RecallSnapshot]) -> [InteractionOverride] {
        var out: [InteractionOverride] = []
        for item in items {
            let derived = newInteractionOverride(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planInteractionOverride(_ item: InteractionOverride) -> String {
        return normalizeDefaultRecallEntryCode(item.code)
    }
}
