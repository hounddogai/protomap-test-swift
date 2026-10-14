import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedSpecimenCyclesForProfile(_ items: [CappedSpecimenCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePendingAccessionProfilesFromCycle(_ items: [CappedSpecimenCycle]) -> [PendingAccessionProfile] {
        var out: [PendingAccessionProfile] = []
        for item in items {
            let derived = newPendingAccessionProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingAccessionProfile(_ item: PendingAccessionProfile) -> Double {
        return cappedSpecimenScheduleWeight(8, active: true)
    }
}
