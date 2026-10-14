import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormEntriesForWindow(_ items: [ConsentFormEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveProxyWindowsFromEntry(_ items: [ConsentFormEntry]) -> [ProxyWindow] {
        var out: [ProxyWindow] = []
        for item in items {
            let derived = newProxyWindow(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceProxyWindow(_ item: ProxyWindow) -> Double {
        return consentFormEntryWeight(8, active: true)
    }
}
