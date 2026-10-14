import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyVariancesForMilestone(_ items: [StudyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePrimaryReadMilestonesFromVariance(_ items: [StudyVariance]) -> [PrimaryReadMilestone] {
        var out: [PrimaryReadMilestone] = []
        for item in items {
            let derived = newPrimaryReadMilestone(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePrimaryReadMilestone(_ item: PrimaryReadMilestone) -> String {
        return studyAgreementBucket(item.effectiveExposure())
    }
}
