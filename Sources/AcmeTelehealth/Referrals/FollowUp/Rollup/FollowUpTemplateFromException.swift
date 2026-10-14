import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotExceptionsForTemplate(_ items: [SlotException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFollowUpTemplatesFromException(_ items: [SlotException]) -> [FollowUpTemplate] {
        var out: [FollowUpTemplate] = []
        for item in items {
            let derived = newFollowUpTemplate(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreFollowUpTemplate(_ item: FollowUpTemplate) -> String {
        return normalizeSlotExceptionCode(item.code)
    }
}
