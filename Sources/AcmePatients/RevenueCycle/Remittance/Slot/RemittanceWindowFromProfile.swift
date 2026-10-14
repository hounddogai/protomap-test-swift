import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementProfilesForWindow(_ items: [StatementProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRemittanceWindowsFromProfile(_ items: [StatementProfile]) -> [RemittanceWindow] {
        var out: [RemittanceWindow] = []
        for item in items {
            let derived = newRemittanceWindow(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRemittanceWindow(_ item: RemittanceWindow) -> String {
        return normalizeStatementTierCode(item.code)
    }
}
