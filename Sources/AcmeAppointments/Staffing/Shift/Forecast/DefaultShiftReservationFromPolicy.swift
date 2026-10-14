import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeTieredCredentialPoliciesForReservation(_ items: [TieredCredentialPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDefaultShiftReservationsFromPolicy(_ items: [TieredCredentialPolicy]) -> [DefaultShiftReservation] {
        var out: [DefaultShiftReservation] = []
        for item in items {
            let derived = newDefaultShiftReservation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultShiftReservation(_ item: DefaultShiftReservation) -> String {
        return normalizeRollingCredentialAllocationCode(item.code)
    }
}
