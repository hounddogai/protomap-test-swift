import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultFollowUpVariancesForCycle(_ items: [DefaultFollowUpVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveFallbackFollowUpCyclesFromVariance(_ items: [DefaultFollowUpVariance]) -> [FallbackFollowUpCycle] {
        var out: [FallbackFollowUpCycle] = []
        for item in items {
            let derived = newFallbackFollowUpCycle(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackFollowUpCycle(_ item: FallbackFollowUpCycle) -> String {
        return classifyCappedFollowUpCheckpoint(item.projectedVolume())
    }
}
