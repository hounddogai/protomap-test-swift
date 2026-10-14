import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingSkillMixManifestsForBatch(_ items: [RollingSkillMixManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveCredentialBatchesFromManifest(_ items: [RollingSkillMixManifest]) -> [CredentialBatch] {
        var out: [CredentialBatch] = []
        for item in items {
            let derived = newCredentialBatch(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileCredentialBatch(_ item: CredentialBatch) -> Double {
        return rollingSkillMixManifestWeight(1, active: true)
    }
}
