import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationTargetsForRequest(_ items: [RevocationTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveDisclosureRequestsFromTarget(_ items: [RevocationTarget]) -> [DisclosureRequest] {
        var out: [DisclosureRequest] = []
        for item in items {
            let derived = newDisclosureRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDisclosureRequest(_ item: DisclosureRequest) -> String {
        return classifyRevocationAssignment(item.adjustedExposure())
    }
}
