import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLenientShiftThresholdsForMapping(_ items: [LenientShiftThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAdaptiveCredentialMappingsFromThreshold(_ items: [LenientShiftThreshold]) -> [AdaptiveCredentialMapping] {
        var out: [AdaptiveCredentialMapping] = []
        for item in items {
            let derived = newAdaptiveCredentialMapping(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeAdaptiveCredentialMapping(_ item: AdaptiveCredentialMapping) -> String {
        return normalizeLenientShiftThresholdCode(item.code)
    }
}
