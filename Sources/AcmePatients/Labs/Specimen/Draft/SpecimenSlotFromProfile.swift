import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelProfilesForSlot(_ items: [PanelProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveSpecimenSlotsFromProfile(_ items: [PanelProfile]) -> [SpecimenSlot] {
        var out: [SpecimenSlot] = []
        for item in items {
            let derived = newSpecimenSlot(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignSpecimenSlot(_ item: SpecimenSlot) -> String {
        return normalizePanelBundleCode(item.code)
    }
}
