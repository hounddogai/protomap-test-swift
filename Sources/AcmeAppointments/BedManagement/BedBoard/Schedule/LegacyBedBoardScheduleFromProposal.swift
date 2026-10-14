import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCensusProposalsForSchedule(_ items: [PrimaryCensusProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLegacyBedBoardSchedulesFromProposal(_ items: [PrimaryCensusProposal]) -> [LegacyBedBoardSchedule] {
        var out: [LegacyBedBoardSchedule] = []
        for item in items {
            let derived = newLegacyBedBoardSchedule(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacyBedBoardSchedule(_ item: LegacyBedBoardSchedule) -> String {
        return normalizeCensusDigestCode(item.code)
    }
}
