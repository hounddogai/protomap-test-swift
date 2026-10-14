import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionEstimatesForVariance(_ items: [InteractionEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveInteractionVariancesFromEstimate(_ items: [InteractionEstimate]) -> [InteractionVariance] {
        var out: [InteractionVariance] = []
        for item in items {
            let derived = newInteractionVariance(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateInteractionVariance(_ item: InteractionVariance) -> Double {
        return adaptiveInteractionDigestWeight(6, active: true)
    }
}
