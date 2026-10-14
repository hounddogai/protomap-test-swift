import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictModalitySnapshotsForProfile(_ items: [StrictModalitySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLenientWorklistProfilesFromSnapshot(_ items: [StrictModalitySnapshot]) -> [LenientWorklistProfile] {
        var out: [LenientWorklistProfile] = []
        for item in items {
            let derived = newLenientWorklistProfile(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLenientWorklistProfile(_ item: LenientWorklistProfile) -> Double {
        return rollingModalityCycleWeight(3, active: true)
    }
}
