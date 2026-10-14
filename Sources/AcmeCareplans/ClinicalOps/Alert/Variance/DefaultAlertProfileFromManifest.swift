import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAdaptiveTaskManifestsForProfile(_ items: [AdaptiveTaskManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultAlertProfilesFromManifest(_ items: [AdaptiveTaskManifest]) -> [DefaultAlertProfile] {
        var out: [DefaultAlertProfile] = []
        for item in items {
            let derived = newDefaultAlertProfile(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultAlertProfile(_ item: DefaultAlertProfile) -> String {
        return classifyAdaptiveTaskManifest(item.effectiveValue())
    }
}
