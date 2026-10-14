import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionMilestonesForBundle(_ items: [SubstitutionMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveLenientDispenseBundlesFromMilestone(_ items: [SubstitutionMilestone]) -> [LenientDispenseBundle] {
        var out: [LenientDispenseBundle] = []
        for item in items {
            let derived = newLenientDispenseBundle(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankLenientDispenseBundle(_ item: LenientDispenseBundle) -> String {
        return classifyCappedSubstitutionBaseline(item.projectedExposure())
    }
}
