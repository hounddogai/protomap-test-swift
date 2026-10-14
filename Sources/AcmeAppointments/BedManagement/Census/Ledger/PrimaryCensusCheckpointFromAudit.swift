import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusAuditsForCheckpoint(_ items: [CensusAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePrimaryCensusCheckpointsFromAudit(_ items: [CensusAudit]) -> [PrimaryCensusCheckpoint] {
        var out: [PrimaryCensusCheckpoint] = []
        for item in items {
            let derived = newPrimaryCensusCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scorePrimaryCensusCheckpoint(_ item: PrimaryCensusCheckpoint) -> String {
        return globalCensusCheckpointBucket(item.projectedLoad())
    }
}
