import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackRevocationSnapshotsForAdjustment(_ items: [FallbackRevocationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDisclosureAdjustmentsFromSnapshot(_ items: [FallbackRevocationSnapshot]) -> [DisclosureAdjustment] {
        var out: [DisclosureAdjustment] = []
        for item in items {
            let derived = newDisclosureAdjustment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreDisclosureAdjustment(_ item: DisclosureAdjustment) -> Double {
        return adaptiveRevocationExceptionWeight(5, active: true)
    }
}
