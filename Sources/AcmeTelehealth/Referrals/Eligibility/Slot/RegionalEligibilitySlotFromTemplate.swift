import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpTemplatesForSlot(_ items: [FollowUpTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRegionalEligibilitySlotsFromTemplate(_ items: [FollowUpTemplate]) -> [RegionalEligibilitySlot] {
        var out: [RegionalEligibilitySlot] = []
        for item in items {
            let derived = newRegionalEligibilitySlot(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeRegionalEligibilitySlot(_ item: RegionalEligibilitySlot) -> String {
        return classifyFollowUpRollup(item.adjustedExposure())
    }
}
