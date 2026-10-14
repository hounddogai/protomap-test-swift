import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyFormularySnapshotsForBaseline(_ items: [LegacyFormularySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFormularyBaselinesFromSnapshot(_ items: [LegacyFormularySnapshot]) -> [FormularyBaseline] {
        var out: [FormularyBaseline] = []
        for item in items {
            let derived = newFormularyBaseline(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFormularyBaseline(_ item: FormularyBaseline) -> String {
        return classifyLegacyFormularySnapshot(item.projectedTotal())
    }
}
