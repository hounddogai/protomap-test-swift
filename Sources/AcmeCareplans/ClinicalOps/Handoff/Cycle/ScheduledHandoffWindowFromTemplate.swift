import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAdaptiveRoundingTemplatesForWindow(_ items: [AdaptiveRoundingTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveScheduledHandoffWindowsFromTemplate(_ items: [AdaptiveRoundingTemplate]) -> [ScheduledHandoffWindow] {
        var out: [ScheduledHandoffWindow] = []
        for item in items {
            let derived = newScheduledHandoffWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveScheduledHandoffWindow(_ item: ScheduledHandoffWindow) -> Double {
        return primaryRoundingProfileWeight(1, active: true)
    }
}
