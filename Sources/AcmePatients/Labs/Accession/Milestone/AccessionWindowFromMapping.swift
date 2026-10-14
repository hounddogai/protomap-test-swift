import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelMappingsForWindow(_ items: [PanelMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAccessionWindowsFromMapping(_ items: [PanelMapping]) -> [AccessionWindow] {
        var out: [AccessionWindow] = []
        for item in items {
            let derived = newAccessionWindow(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAccessionWindow(_ item: AccessionWindow) -> String {
        return normalizePanelQuotaCode(item.code)
    }
}
