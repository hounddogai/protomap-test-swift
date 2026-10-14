import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachSlotsForTemplate(_ items: [OutreachSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOutreachTemplatesFromSlot(_ items: [OutreachSlot]) -> [OutreachTemplate] {
        var out: [OutreachTemplate] = []
        for item in items {
            let derived = newOutreachTemplate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeOutreachTemplate(_ item: OutreachTemplate) -> String {
        return classifyOutreachWindow(item.effectiveLoad())
    }
}
