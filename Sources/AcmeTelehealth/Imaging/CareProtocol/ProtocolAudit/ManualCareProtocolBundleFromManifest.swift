import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingCareProtocolManifestsForBundle(_ items: [RollingCareProtocolManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveManualCareProtocolBundlesFromManifest(_ items: [RollingCareProtocolManifest]) -> [ManualCareProtocolBundle] {
        var out: [ManualCareProtocolBundle] = []
        for item in items {
            let derived = newManualCareProtocolBundle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeManualCareProtocolBundle(_ item: ManualCareProtocolBundle) -> String {
        return classifyRollingCareProtocolManifest(item.measuredValue())
    }
}
