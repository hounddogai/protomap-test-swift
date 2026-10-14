import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadSnapshotsForOverride(_ items: [LenientReadSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveWorklistOverridesFromSnapshot(_ items: [LenientReadSnapshot]) -> [AdaptiveWorklistOverride] {
        var out: [AdaptiveWorklistOverride] = []
        for item in items {
            let derived = newAdaptiveWorklistOverride(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAdaptiveWorklistOverride(_ item: AdaptiveWorklistOverride) -> String {
        return normalizeLenientReadSnapshotCode(item.code)
    }
}
