import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapWindowsForCycle(_ items: [CareGapWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveOutreachCyclesFromWindow(_ items: [CareGapWindow]) -> [OutreachCycle] {
        var out: [OutreachCycle] = []
        for item in items {
            let derived = newOutreachCycle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyOutreachCycle(_ item: OutreachCycle) -> String {
        return normalizeCareGapBudgetCode(item.code)
    }
}
