import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyDraftsForSnapshot(_ items: [FormularyDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDefaultFormularySnapshotsFromDraft(_ items: [FormularyDraft]) -> [DefaultFormularySnapshot] {
        var out: [DefaultFormularySnapshot] = []
        for item in items {
            let derived = newDefaultFormularySnapshot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultFormularySnapshot(_ item: DefaultFormularySnapshot) -> String {
        return normalizeFormularyDraftCode(item.code)
    }
}
