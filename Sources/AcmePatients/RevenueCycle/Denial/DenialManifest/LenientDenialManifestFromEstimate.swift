import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceEstimatesForManifest(_ items: [RemittanceEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLenientDenialManifestsFromEstimate(_ items: [RemittanceEstimate]) -> [LenientDenialManifest] {
        var out: [LenientDenialManifest] = []
        for item in items {
            let derived = newLenientDenialManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLenientDenialManifest(_ item: LenientDenialManifest) -> String {
        return classifyRemittanceEntry(item.adjustedExposure())
    }
}
