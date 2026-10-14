import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskQuotasForProfile(_ items: [TaskQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveRoundingProfilesFromQuota(_ items: [TaskQuota]) -> [RoundingProfile] {
        var out: [RoundingProfile] = []
        for item in items {
            let derived = newRoundingProfile(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRoundingProfile(_ item: RoundingProfile) -> Double {
        return taskProposalWeight(2, active: true)
    }
}
