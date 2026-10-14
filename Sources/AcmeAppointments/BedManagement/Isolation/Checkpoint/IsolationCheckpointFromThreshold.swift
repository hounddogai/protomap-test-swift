import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedTransferThresholdsForCheckpoint(_ items: [CappedTransferThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveIsolationCheckpointsFromThreshold(_ items: [CappedTransferThreshold]) -> [IsolationCheckpoint] {
        var out: [IsolationCheckpoint] = []
        for item in items {
            let derived = newIsolationCheckpoint(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeIsolationCheckpoint(_ item: IsolationCheckpoint) -> String {
        return manualTransferTemplateBucket(item.effectiveLoad())
    }
}
