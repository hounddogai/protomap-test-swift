import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkCheckpointsForException(_ items: [NetworkCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCappedReferralExceptionsFromCheckpoint(_ items: [NetworkCheckpoint]) -> [CappedReferralException] {
        var out: [CappedReferralException] = []
        for item in items {
            let derived = newCappedReferralException(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCappedReferralException(_ item: CappedReferralException) -> String {
        return classifyFallbackNetworkCheckpoint(item.projectedExposure())
    }
}
