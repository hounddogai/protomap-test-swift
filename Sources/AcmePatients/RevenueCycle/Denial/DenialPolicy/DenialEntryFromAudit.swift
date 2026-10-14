import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialAuditsForEntry(_ items: [DenialAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDenialEntriesFromAudit(_ items: [DenialAudit]) -> [DenialEntry] {
        var out: [DenialEntry] = []
        for item in items {
            let derived = newDenialEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDenialEntry(_ item: DenialEntry) -> Double {
        return denialAuditWeight(1, active: true)
    }
}
