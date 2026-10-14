import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualDischargePlanProfilesForTier(_ items: [ManualDischargePlanProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveBedBoardTiersFromProfile(_ items: [ManualDischargePlanProfile]) -> [BedBoardTier] {
        var out: [BedBoardTier] = []
        for item in items {
            let derived = newBedBoardTier(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignBedBoardTier(_ item: BedBoardTier) -> String {
        return classifyDischargePlanNotice(item.projectedTotal())
    }
}
