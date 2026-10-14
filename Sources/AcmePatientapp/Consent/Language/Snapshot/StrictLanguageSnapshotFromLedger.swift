import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyLedgersForSnapshot(_ items: [ProxyLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictLanguageSnapshotsFromLedger(_ items: [ProxyLedger]) -> [StrictLanguageSnapshot] {
        var out: [StrictLanguageSnapshot] = []
        for item in items {
            let derived = newStrictLanguageSnapshot(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeStrictLanguageSnapshot(_ item: StrictLanguageSnapshot) -> String {
        return normalizeProxyLedgerCode(item.code)
    }
}
