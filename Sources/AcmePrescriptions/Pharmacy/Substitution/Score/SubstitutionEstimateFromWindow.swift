import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionWindowsForEstimate(_ items: [InteractionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveSubstitutionEstimatesFromWindow(_ items: [InteractionWindow]) -> [SubstitutionEstimate] {
        var out: [SubstitutionEstimate] = []
        for item in items {
            let derived = newSubstitutionEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeSubstitutionEstimate(_ item: SubstitutionEstimate) -> String {
        return classifyInteractionWindow(item.weightedTotal())
    }
}
