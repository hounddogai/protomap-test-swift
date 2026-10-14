import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertDraftsForWindow(_ items: [AlertDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveLenientTaskWindowsFromDraft(_ items: [AlertDraft]) -> [LenientTaskWindow] {
        var out: [LenientTaskWindow] = []
        for item in items {
            let derived = newLenientTaskWindow(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientTaskWindow(_ item: LenientTaskWindow) -> String {
        return classifyAlertLedger(item.adjustedValue())
    }
}
