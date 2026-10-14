import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyExceptionsForQuota(_ items: [ProxyException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLanguageQuotasFromException(_ items: [ProxyException]) -> [LanguageQuota] {
        var out: [LanguageQuota] = []
        for item in items {
            let derived = newLanguageQuota(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankLanguageQuota(_ item: LanguageQuota) -> String {
        return normalizeStrictProxyVarianceCode(item.code)
    }
}
