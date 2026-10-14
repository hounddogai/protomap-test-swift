import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientReferenceRangeVariancesForSchedule(_ items: [LenientReferenceRangeVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedSpecimenSchedulesFromVariance(_ items: [LenientReferenceRangeVariance]) -> [CappedSpecimenSchedule] {
        var out: [CappedSpecimenSchedule] = []
        for item in items {
            let derived = newCappedSpecimenSchedule(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedSpecimenSchedule(_ item: CappedSpecimenSchedule) -> String {
        return classifyLegacyReferenceRangeManifest(item.measuredValue())
    }
}
