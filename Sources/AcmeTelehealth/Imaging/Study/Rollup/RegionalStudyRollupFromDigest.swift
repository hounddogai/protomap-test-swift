import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalReadDigestsForRollup(_ items: [GlobalReadDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRegionalStudyRollupsFromDigest(_ items: [GlobalReadDigest]) -> [RegionalStudyRollup] {
        var out: [RegionalStudyRollup] = []
        for item in items {
            let derived = newRegionalStudyRollup(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalStudyRollup(_ item: RegionalStudyRollup) -> String {
        return cappedReadBaselineBucket(item.projectedLoad())
    }
}
