import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixEntriesForWindow(_ items: [SkillMixEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSkillMixWindowsFromEntry(_ items: [SkillMixEntry]) -> [SkillMixWindow] {
        var out: [SkillMixWindow] = []
        for item in items {
            let derived = newSkillMixWindow(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveSkillMixWindow(_ item: SkillMixWindow) -> String {
        return normalizeSkillMixEntryCode(item.code)
    }
}
