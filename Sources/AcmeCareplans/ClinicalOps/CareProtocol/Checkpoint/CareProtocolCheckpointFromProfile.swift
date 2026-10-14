import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolProfilesForCheckpoint(_ items: [CareProtocolProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolCheckpointsFromProfile(_ items: [CareProtocolProfile]) -> [CareProtocolCheckpoint] {
        var out: [CareProtocolCheckpoint] = []
        for item in items {
            let derived = newCareProtocolCheckpoint(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitCareProtocolCheckpoint(_ item: CareProtocolCheckpoint) -> String {
        return classifyCareProtocolTarget(item.effectiveValue())
    }
}
