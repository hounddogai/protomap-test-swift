import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedDispenseAdjustmentsForProfile(_ items: [CappedDispenseAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDefaultInteractionProfilesFromAdjustment(_ items: [CappedDispenseAdjustment]) -> [DefaultInteractionProfile] {
        var out: [DefaultInteractionProfile] = []
        for item in items {
            let derived = newDefaultInteractionProfile(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleDefaultInteractionProfile(_ item: DefaultInteractionProfile) -> String {
        return classifyDispenseWindow(item.netExposure())
    }
}
