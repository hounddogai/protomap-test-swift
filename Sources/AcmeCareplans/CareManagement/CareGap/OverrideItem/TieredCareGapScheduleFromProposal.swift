import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapProposalsForSchedule(_ items: [CareGapProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveTieredCareGapSchedulesFromProposal(_ items: [CareGapProposal]) -> [TieredCareGapSchedule] {
        var out: [TieredCareGapSchedule] = []
        for item in items {
            let derived = newTieredCareGapSchedule(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreTieredCareGapSchedule(_ item: TieredCareGapSchedule) -> String {
        return classifyCareGapProposal(item.projectedExposure())
    }
}
