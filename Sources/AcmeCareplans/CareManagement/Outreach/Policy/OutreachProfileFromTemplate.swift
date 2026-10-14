import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalTemplatesForProfile(_ items: [GoalTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveOutreachProfilesFromTemplate(_ items: [GoalTemplate]) -> [OutreachProfile] {
        var out: [OutreachProfile] = []
        for item in items {
            let derived = newOutreachProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOutreachProfile(_ item: OutreachProfile) -> String {
        return normalizeGoalTemplateCode(item.code)
    }
}
