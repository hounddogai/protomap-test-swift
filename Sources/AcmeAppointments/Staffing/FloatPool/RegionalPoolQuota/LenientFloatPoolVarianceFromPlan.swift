import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialPlansForVariance(_ items: [CredentialPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientFloatPoolVariancesFromPlan(_ items: [CredentialPlan]) -> [LenientFloatPoolVariance] {
        var out: [LenientFloatPoolVariance] = []
        for item in items {
            let derived = newLenientFloatPoolVariance(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientFloatPoolVariance(_ item: LenientFloatPoolVariance) -> String {
        return normalizeCredentialWindowCode(item.code)
    }
}
