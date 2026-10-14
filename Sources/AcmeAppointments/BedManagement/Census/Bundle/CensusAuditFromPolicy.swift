import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferPoliciesForAudit(_ items: [TransferPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCensusAuditsFromPolicy(_ items: [TransferPolicy]) -> [CensusAudit] {
        var out: [CensusAudit] = []
        for item in items {
            let derived = newCensusAudit(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCensusAudit(_ item: CensusAudit) -> String {
        return weightedTransferGroupBucket(item.netLoad())
    }
}
