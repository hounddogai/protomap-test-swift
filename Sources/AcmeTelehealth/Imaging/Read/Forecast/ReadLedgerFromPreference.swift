import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolPreferencesForLedger(_ items: [CareProtocolPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReadLedgersFromPreference(_ items: [CareProtocolPreference]) -> [ReadLedger] {
        var out: [ReadLedger] = []
        for item in items {
            let derived = newReadLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planReadLedger(_ item: ReadLedger) -> String {
        return classifyCareProtocolMapping(item.netExposure())
    }
}
