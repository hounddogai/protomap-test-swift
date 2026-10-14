import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualResultBaselinesForTemplate(_ items: [ManualResultBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingPanelTemplatesFromBaseline(_ items: [ManualResultBaseline]) -> [PendingPanelTemplate] {
        var out: [PendingPanelTemplate] = []
        for item in items {
            let derived = newPendingPanelTemplate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingPanelTemplate(_ item: PendingPanelTemplate) -> String {
        return classifyAdaptiveResultRequest(item.adjustedValue())
    }
}
