import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientResultAgreementsForRequest(_ items: [LenientResultAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveAdaptiveResultRequestsFromAgreement(_ items: [LenientResultAgreement]) -> [AdaptiveResultRequest] {
        var out: [AdaptiveResultRequest] = []
        for item in items {
            let derived = newAdaptiveResultRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveResultRequest(_ item: AdaptiveResultRequest) -> String {
        return lenientResultAgreementBucket(item.projectedExposure())
    }
}
