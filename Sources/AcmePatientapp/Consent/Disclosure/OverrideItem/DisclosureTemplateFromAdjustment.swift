import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessAdjustmentsForTemplate(_ items: [WitnessAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDisclosureTemplatesFromAdjustment(_ items: [WitnessAdjustment]) -> [DisclosureTemplate] {
        var out: [DisclosureTemplate] = []
        for item in items {
            let derived = newDisclosureTemplate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDisclosureTemplate(_ item: DisclosureTemplate) -> String {
        return normalizeSeasonalWitnessBudgetCode(item.code)
    }
}
