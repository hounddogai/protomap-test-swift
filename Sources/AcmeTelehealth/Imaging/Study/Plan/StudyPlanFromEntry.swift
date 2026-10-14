import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLegacyCareProtocolEntriesForPlan(_ items: [LegacyCareProtocolEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveStudyPlansFromEntry(_ items: [LegacyCareProtocolEntry]) -> [StudyPlan] {
        var out: [StudyPlan] = []
        for item in items {
            let derived = newStudyPlan(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitStudyPlan(_ item: StudyPlan) -> Double {
        return legacyCareProtocolEntryWeight(7, active: true)
    }
}
