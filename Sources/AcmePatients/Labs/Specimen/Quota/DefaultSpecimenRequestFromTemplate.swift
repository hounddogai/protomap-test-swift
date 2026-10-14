import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelTemplatesForRequest(_ items: [PanelTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultSpecimenRequestsFromTemplate(_ items: [PanelTemplate]) -> [DefaultSpecimenRequest] {
        var out: [DefaultSpecimenRequest] = []
        for item in items {
            let derived = newDefaultSpecimenRequest(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveDefaultSpecimenRequest(_ item: DefaultSpecimenRequest) -> String {
        return fallbackPanelProfileBucket(item.effectiveLoad())
    }
}
