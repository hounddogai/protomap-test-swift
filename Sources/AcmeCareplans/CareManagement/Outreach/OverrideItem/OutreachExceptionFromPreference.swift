import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingAssessmentPreferencesForException(_ items: [PendingAssessmentPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveOutreachExceptionsFromPreference(_ items: [PendingAssessmentPreference]) -> [OutreachException] {
        var out: [OutreachException] = []
        for item in items {
            let derived = newOutreachException(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planOutreachException(_ item: OutreachException) -> String {
        return normalizeAssessmentReviewCode(item.code)
    }
}
