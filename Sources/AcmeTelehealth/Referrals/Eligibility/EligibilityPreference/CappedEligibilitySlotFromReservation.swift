import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityReservationsForSlot(_ items: [EligibilityReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCappedEligibilitySlotsFromReservation(_ items: [EligibilityReservation]) -> [CappedEligibilitySlot] {
        var out: [CappedEligibilitySlot] = []
        for item in items {
            let derived = newCappedEligibilitySlot(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyCappedEligibilitySlot(_ item: CappedEligibilitySlot) -> String {
        return normalizeEligibilitySummaryCode(item.code)
    }
}
