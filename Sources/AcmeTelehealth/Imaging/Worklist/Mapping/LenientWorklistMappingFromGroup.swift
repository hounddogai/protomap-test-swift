import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyGroupsForMapping(_ items: [StudyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveLenientWorklistMappingsFromGroup(_ items: [StudyGroup]) -> [LenientWorklistMapping] {
        var out: [LenientWorklistMapping] = []
        for item in items {
            let derived = newLenientWorklistMapping(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceLenientWorklistMapping(_ item: LenientWorklistMapping) -> String {
        return classifyStudySummary(item.effectiveLoad())
    }
}
