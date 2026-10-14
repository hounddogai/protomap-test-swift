import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultCredentialRequestsForWindow(_ items: [DefaultCredentialRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePrimaryShiftWindowsFromRequest(_ items: [DefaultCredentialRequest]) -> [PrimaryShiftWindow] {
        var out: [PrimaryShiftWindow] = []
        for item in items {
            let derived = newPrimaryShiftWindow(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryShiftWindow(_ item: PrimaryShiftWindow) -> String {
        return normalizeDefaultCredentialClaimCode(item.code)
    }
}
