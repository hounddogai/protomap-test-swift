import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageAssignmentsForAdjustment(_ items: [LanguageAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDisclosureAdjustmentsFromAssignment(_ items: [LanguageAssignment]) -> [DisclosureAdjustment] {
        var out: [DisclosureAdjustment] = []
        for item in items {
            let derived = newDisclosureAdjustment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchDisclosureAdjustment(_ item: DisclosureAdjustment) -> Double {
        return languageSnapshotWeight(8, active: true)
    }
}
