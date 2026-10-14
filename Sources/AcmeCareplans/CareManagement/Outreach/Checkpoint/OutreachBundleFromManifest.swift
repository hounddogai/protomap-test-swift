import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachManifestsForBundle(_ items: [OutreachManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveOutreachBundlesFromManifest(_ items: [OutreachManifest]) -> [OutreachBundle] {
        var out: [OutreachBundle] = []
        for item in items {
            let derived = newOutreachBundle(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleOutreachBundle(_ item: OutreachBundle) -> Double {
        return outreachAuditWeight(9, active: true)
    }
}
