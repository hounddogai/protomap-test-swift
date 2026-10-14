import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCensusCheckpointsForEntry(_ items: [PrimaryCensusCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveGlobalTransferEntriesFromCheckpoint(_ items: [PrimaryCensusCheckpoint]) -> [GlobalTransferEntry] {
        var out: [GlobalTransferEntry] = []
        for item in items {
            let derived = newGlobalTransferEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalTransferEntry(_ item: GlobalTransferEntry) -> String {
        return primaryCensusCheckpointBucket(item.projectedVolume())
    }
}
