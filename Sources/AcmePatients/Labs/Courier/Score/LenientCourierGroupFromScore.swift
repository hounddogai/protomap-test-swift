import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenScoresForGroup(_ items: [SpecimenScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientCourierGroupsFromScore(_ items: [SpecimenScore]) -> [LenientCourierGroup] {
        var out: [LenientCourierGroup] = []
        for item in items {
            let derived = newLenientCourierGroup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLenientCourierGroup(_ item: LenientCourierGroup) -> String {
        return classifySpecimenScore(item.measuredValue())
    }
}
