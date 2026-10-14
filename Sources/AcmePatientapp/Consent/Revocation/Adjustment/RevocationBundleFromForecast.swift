import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalDisclosureForecastsForBundle(_ items: [GlobalDisclosureForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRevocationBundlesFromForecast(_ items: [GlobalDisclosureForecast]) -> [RevocationBundle] {
        var out: [RevocationBundle] = []
        for item in items {
            let derived = newRevocationBundle(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRevocationBundle(_ item: RevocationBundle) -> String {
        return normalizeGlobalDisclosureForecastCode(item.code)
    }
}
