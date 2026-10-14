import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryCourierDigestsForAgreement(_ items: [PrimaryCourierDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveSeasonalAccessionAgreementsFromDigest(_ items: [PrimaryCourierDigest]) -> [SeasonalAccessionAgreement] {
        var out: [SeasonalAccessionAgreement] = []
        for item in items {
            let derived = newSeasonalAccessionAgreement(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalAccessionAgreement(_ item: SeasonalAccessionAgreement) -> String {
        return primaryCourierDigestBucket(item.netExposure())
    }
}
