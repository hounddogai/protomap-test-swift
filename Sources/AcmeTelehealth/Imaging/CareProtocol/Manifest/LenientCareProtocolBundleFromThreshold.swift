import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryPriorityThresholdsForBundle(_ items: [PrimaryPriorityThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLenientCareProtocolBundlesFromThreshold(_ items: [PrimaryPriorityThreshold]) -> [LenientCareProtocolBundle] {
        var out: [LenientCareProtocolBundle] = []
        for item in items {
            let derived = newLenientCareProtocolBundle(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientCareProtocolBundle(_ item: LenientCareProtocolBundle) -> String {
        return normalizePrimaryPriorityThresholdCode(item.code)
    }
}
