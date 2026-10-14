import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageRequestsForRequest(_ items: [LanguageRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveConsentFormRequestsFromRequest(_ items: [LanguageRequest]) -> [ConsentFormRequest] {
        var out: [ConsentFormRequest] = []
        for item in items {
            let derived = newConsentFormRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeConsentFormRequest(_ item: ConsentFormRequest) -> String {
        return languageCheckpointBucket(item.weightedVolume())
    }
}
