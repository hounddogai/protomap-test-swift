import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelSchedulesForMapping(_ items: [PanelSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCourierMappingsFromSchedule(_ items: [PanelSchedule]) -> [CourierMapping] {
        var out: [CourierMapping] = []
        for item in items {
            let derived = newCourierMapping(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveCourierMapping(_ item: CourierMapping) -> Double {
        return panelProfileWeight(4, active: true)
    }
}
