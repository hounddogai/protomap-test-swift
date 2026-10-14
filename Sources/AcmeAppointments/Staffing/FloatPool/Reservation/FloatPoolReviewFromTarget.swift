import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialTargetsForReview(_ items: [CredentialTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFloatPoolReviewsFromTarget(_ items: [CredentialTarget]) -> [FloatPoolReview] {
        var out: [FloatPoolReview] = []
        for item in items {
            let derived = newFloatPoolReview(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFloatPoolReview(_ item: FloatPoolReview) -> String {
        return normalizeCredentialPolicyCode(item.code)
    }
}
