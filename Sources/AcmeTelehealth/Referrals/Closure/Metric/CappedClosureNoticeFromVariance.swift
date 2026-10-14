import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultFollowUpVariancesForNotice(_ items: [DefaultFollowUpVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveCappedClosureNoticesFromVariance(_ items: [DefaultFollowUpVariance]) -> [CappedClosureNotice] {
        var out: [CappedClosureNotice] = []
        for item in items {
            let derived = newCappedClosureNotice(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCappedClosureNotice(_ item: CappedClosureNotice) -> String {
        return normalizeCappedFollowUpCheckpointCode(item.code)
    }
}
