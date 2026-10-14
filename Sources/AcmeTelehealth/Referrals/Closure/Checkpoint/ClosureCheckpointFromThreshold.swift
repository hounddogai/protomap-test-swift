import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralThresholdsForCheckpoint(_ items: [ReferralThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveClosureCheckpointsFromThreshold(_ items: [ReferralThreshold]) -> [ClosureCheckpoint] {
        var out: [ClosureCheckpoint] = []
        for item in items {
            let derived = newClosureCheckpoint(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planClosureCheckpoint(_ item: ClosureCheckpoint) -> String {
        return normalizeReferralTierCode(item.code)
    }
}
