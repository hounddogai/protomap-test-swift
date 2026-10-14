import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalRevocationGroupsForBundle(_ items: [GlobalRevocationGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRevocationBundlesFromGroup(_ items: [GlobalRevocationGroup]) -> [RevocationBundle] {
        var out: [RevocationBundle] = []
        for item in items {
            let derived = newRevocationBundle(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRevocationBundle(_ item: RevocationBundle) -> String {
        return normalizeGlobalRevocationGroupCode(item.code)
    }
}
