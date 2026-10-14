import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalOutreachDigestsForQuota(_ items: [SeasonalOutreachDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveTieredProgramQuotasFromDigest(_ items: [SeasonalOutreachDigest]) -> [TieredProgramQuota] {
        var out: [TieredProgramQuota] = []
        for item in items {
            let derived = newTieredProgramQuota(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchTieredProgramQuota(_ item: TieredProgramQuota) -> String {
        return normalizeLenientOutreachProposalCode(item.code)
    }
}
