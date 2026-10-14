import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackResultClaimsForReservation(_ items: [FallbackResultClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveDefaultAccessionReservationsFromClaim(_ items: [FallbackResultClaim]) -> [DefaultAccessionReservation] {
        var out: [DefaultAccessionReservation] = []
        for item in items {
            let derived = newDefaultAccessionReservation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultAccessionReservation(_ item: DefaultAccessionReservation) -> String {
        return classifyLegacyResultVariance(item.adjustedLoad())
    }
}
