import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftBundlesForBundle(_ items: [ShiftBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCredentialBundlesFromBundle(_ items: [ShiftBundle]) -> [CredentialBundle] {
        var out: [CredentialBundle] = []
        for item in items {
            let derived = newCredentialBundle(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCredentialBundle(_ item: CredentialBundle) -> String {
        return normalizeShiftDigestCode(item.code)
    }
}
