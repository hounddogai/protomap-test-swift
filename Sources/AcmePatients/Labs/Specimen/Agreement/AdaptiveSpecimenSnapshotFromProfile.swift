import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierProfilesForSnapshot(_ items: [CourierProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAdaptiveSpecimenSnapshotsFromProfile(_ items: [CourierProfile]) -> [AdaptiveSpecimenSnapshot] {
        var out: [AdaptiveSpecimenSnapshot] = []
        for item in items {
            let derived = newAdaptiveSpecimenSnapshot(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveSpecimenSnapshot(_ item: AdaptiveSpecimenSnapshot) -> Double {
        return defaultCourierProposalWeight(9, active: true)
    }
}
