import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationExceptionsForSummary(_ items: [AuthorizationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveDenialSummariesFromException(_ items: [AuthorizationException]) -> [DenialSummary] {
        var out: [DenialSummary] = []
        for item in items {
            let derived = newDenialSummary(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDenialSummary(_ item: DenialSummary) -> String {
        return classifyLenientAuthorizationVariance(item.netLoad())
    }
}
