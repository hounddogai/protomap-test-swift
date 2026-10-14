import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientProxyEntriesForAudit(_ items: [LenientProxyEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLanguageAuditsFromEntry(_ items: [LenientProxyEntry]) -> [LanguageAudit] {
        var out: [LanguageAudit] = []
        for item in items {
            let derived = newLanguageAudit(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectLanguageAudit(_ item: LanguageAudit) -> Double {
        return proxyReviewWeight(2, active: true)
    }
}
