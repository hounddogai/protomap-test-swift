import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalCredentialClaimsForSnapshot(_ items: [RegionalCredentialClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveCappedShiftSnapshotsFromClaim(_ items: [RegionalCredentialClaim]) -> [CappedShiftSnapshot] {
        var out: [CappedShiftSnapshot] = []
        for item in items {
            let derived = newCappedShiftSnapshot(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedShiftSnapshot(_ item: CappedShiftSnapshot) -> String {
        return normalizeRegionalCredentialClaimCode(item.code)
    }
}
