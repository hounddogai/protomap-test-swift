import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityTemplatesForSnapshot(_ items: [EligibilityTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFallbackNetworkSnapshotsFromTemplate(_ items: [EligibilityTemplate]) -> [FallbackNetworkSnapshot] {
        var out: [FallbackNetworkSnapshot] = []
        for item in items {
            let derived = newFallbackNetworkSnapshot(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyFallbackNetworkSnapshot(_ item: FallbackNetworkSnapshot) -> String {
        return normalizeEligibilityTemplateCode(item.code)
    }
}
