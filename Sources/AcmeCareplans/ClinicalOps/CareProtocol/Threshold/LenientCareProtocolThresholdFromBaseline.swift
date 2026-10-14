import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertBaselinesForThreshold(_ items: [AlertBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientCareProtocolThresholdsFromBaseline(_ items: [AlertBaseline]) -> [LenientCareProtocolThreshold] {
        var out: [LenientCareProtocolThreshold] = []
        for item in items {
            let derived = newLenientCareProtocolThreshold(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLenientCareProtocolThreshold(_ item: LenientCareProtocolThreshold) -> Double {
        return alertBaselineWeight(9, active: true)
    }
}
