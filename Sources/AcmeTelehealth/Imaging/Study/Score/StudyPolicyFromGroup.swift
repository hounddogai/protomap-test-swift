import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityGroupsForPolicy(_ items: [ModalityGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveStudyPoliciesFromGroup(_ items: [ModalityGroup]) -> [StudyPolicy] {
        var out: [StudyPolicy] = []
        for item in items {
            let derived = newStudyPolicy(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitStudyPolicy(_ item: StudyPolicy) -> String {
        return normalizeModalityPreferenceCode(item.code)
    }
}
