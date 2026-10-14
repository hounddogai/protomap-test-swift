import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalCredentialTiersForWindow(_ items: [RegionalCredentialTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCredentialWindowsFromTier(_ items: [RegionalCredentialTier]) -> [CredentialWindow] {
        var out: [CredentialWindow] = []
        for item in items {
            let derived = newCredentialWindow(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCredentialWindow(_ item: CredentialWindow) -> String {
        return classifyRegionalCredentialTier(item.netExposure())
    }
}
