import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenAdjustmentsForAssignment(_ items: [SpecimenAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCourierAssignmentsFromAdjustment(_ items: [SpecimenAdjustment]) -> [CourierAssignment] {
        var out: [CourierAssignment] = []
        for item in items {
            let derived = newCourierAssignment(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectCourierAssignment(_ item: CourierAssignment) -> String {
        return normalizeFallbackSpecimenTierCode(item.code)
    }
}
