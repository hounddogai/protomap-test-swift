import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientOrderSetTargetsForProfile(_ items: [LenientOrderSetTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveScheduledCareProtocolProfilesFromTarget(_ items: [LenientOrderSetTarget]) -> [ScheduledCareProtocolProfile] {
        var out: [ScheduledCareProtocolProfile] = []
        for item in items {
            let derived = newScheduledCareProtocolProfile(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectScheduledCareProtocolProfile(_ item: ScheduledCareProtocolProfile) -> Double {
        return orderSetProfileWeight(1, active: true)
    }
}
