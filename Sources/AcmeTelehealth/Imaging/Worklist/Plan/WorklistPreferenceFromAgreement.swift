import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyAgreementsForPreference(_ items: [StudyAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWorklistPreferencesFromAgreement(_ items: [StudyAgreement]) -> [WorklistPreference] {
        var out: [WorklistPreference] = []
        for item in items {
            let derived = newWorklistPreference(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitWorklistPreference(_ item: WorklistPreference) -> Double {
        return studyBudgetWeight(1, active: true)
    }
}
