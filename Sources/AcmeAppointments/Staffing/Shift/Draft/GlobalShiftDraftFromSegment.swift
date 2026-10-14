import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolSegmentsForDraft(_ items: [FloatPoolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveGlobalShiftDraftsFromSegment(_ items: [FloatPoolSegment]) -> [GlobalShiftDraft] {
        var out: [GlobalShiftDraft] = []
        for item in items {
            let derived = newGlobalShiftDraft(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalShiftDraft(_ item: GlobalShiftDraft) -> String {
        return classifyRollingFloatPoolAssignment(item.effectiveVolume())
    }
}
