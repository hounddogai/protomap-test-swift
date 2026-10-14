import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalSubstitutionClaimsForRequest(_ items: [GlobalSubstitutionClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLenientDispenseRequestsFromClaim(_ items: [GlobalSubstitutionClaim]) -> [LenientDispenseRequest] {
        var out: [LenientDispenseRequest] = []
        for item in items {
            let derived = newLenientDispenseRequest(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitLenientDispenseRequest(_ item: LenientDispenseRequest) -> String {
        return classifyPendingSubstitutionAllocation(item.effectiveVolume())
    }
}
