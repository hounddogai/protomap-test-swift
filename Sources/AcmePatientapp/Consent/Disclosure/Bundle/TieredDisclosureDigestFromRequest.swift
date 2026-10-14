import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageRequestsForDigest(_ items: [LanguageRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTieredDisclosureDigestsFromRequest(_ items: [LanguageRequest]) -> [TieredDisclosureDigest] {
        var out: [TieredDisclosureDigest] = []
        for item in items {
            let derived = newTieredDisclosureDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyTieredDisclosureDigest(_ item: TieredDisclosureDigest) -> String {
        return classifyWeightedLanguageDigest(item.projectedVolume())
    }
}
