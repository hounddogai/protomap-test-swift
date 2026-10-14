import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackFormularyAgreementsForDigest(_ items: [FallbackFormularyAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAdaptiveFormularyDigestsFromAgreement(_ items: [FallbackFormularyAgreement]) -> [AdaptiveFormularyDigest] {
        var out: [AdaptiveFormularyDigest] = []
        for item in items {
            let derived = newAdaptiveFormularyDigest(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveFormularyDigest(_ item: AdaptiveFormularyDigest) -> String {
        return classifyDefaultFormularyOverride(item.adjustedValue())
    }
}
