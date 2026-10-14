import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientRoundingProfilesForPreference(_ items: [LenientRoundingProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOrderSetPreferencesFromProfile(_ items: [LenientRoundingProfile]) -> [OrderSetPreference] {
        var out: [OrderSetPreference] = []
        for item in items {
            let derived = newOrderSetPreference(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveOrderSetPreference(_ item: OrderSetPreference) -> Double {
        return adaptiveRoundingTemplateWeight(6, active: true)
    }
}
