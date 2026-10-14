import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimePoliciesForEntry(_ items: [OvertimePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCredentialEntriesFromPolicy(_ items: [OvertimePolicy]) -> [CredentialEntry] {
        var out: [CredentialEntry] = []
        for item in items {
            let derived = newCredentialEntry(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCredentialEntry(_ item: CredentialEntry) -> String {
        return normalizeOvertimePolicyCode(item.code)
    }
}
