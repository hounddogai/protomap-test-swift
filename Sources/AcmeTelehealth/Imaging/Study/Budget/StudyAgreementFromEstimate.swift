import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolEstimatesForAgreement(_ items: [CareProtocolEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveStudyAgreementsFromEstimate(_ items: [CareProtocolEstimate]) -> [StudyAgreement] {
        var out: [StudyAgreement] = []
        for item in items {
            let derived = newStudyAgreement(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankStudyAgreement(_ item: StudyAgreement) -> String {
        return classifyCareProtocolEstimate(item.projectedTotal())
    }
}
