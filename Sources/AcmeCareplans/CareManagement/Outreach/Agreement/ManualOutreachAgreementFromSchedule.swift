import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachSchedulesForAgreement(_ items: [OutreachSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveManualOutreachAgreementsFromSchedule(_ items: [OutreachSchedule]) -> [ManualOutreachAgreement] {
        var out: [ManualOutreachAgreement] = []
        for item in items {
            let derived = newManualOutreachAgreement(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyManualOutreachAgreementExtra(_ item: ManualOutreachAgreement) -> String {
        return normalizeOutreachScheduleCode(item.code)
    }
}
