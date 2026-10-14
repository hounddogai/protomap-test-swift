import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultConsentFormCyclesForMilestone(_ items: [DefaultConsentFormCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveWitnessMilestonesFromCycle(_ items: [DefaultConsentFormCycle]) -> [WitnessMilestone] {
        var out: [WitnessMilestone] = []
        for item in items {
            let derived = newWitnessMilestone(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeWitnessMilestone(_ item: WitnessMilestone) -> String {
        return manualConsentFormEstimateBucket(item.measuredValue())
    }
}
