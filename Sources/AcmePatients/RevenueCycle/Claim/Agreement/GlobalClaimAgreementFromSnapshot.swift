import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyAuthorizationSnapshotsForAgreement(_ items: [LegacyAuthorizationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveGlobalClaimAgreementsFromSnapshot(_ items: [LegacyAuthorizationSnapshot]) -> [GlobalClaimAgreement] {
        var out: [GlobalClaimAgreement] = []
        for item in items {
            let derived = newGlobalClaimAgreement(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalClaimAgreement(_ item: GlobalClaimAgreement) -> Double {
        return legacyAuthorizationSnapshotWeight(5, active: true)
    }
}
