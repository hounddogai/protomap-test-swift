import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolMappingsForDraft(_ items: [FloatPoolMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingOvertimeDraftsFromMapping(_ items: [FloatPoolMapping]) -> [RollingOvertimeDraft] {
        var out: [RollingOvertimeDraft] = []
        for item in items {
            let derived = newRollingOvertimeDraft(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRollingOvertimeDraft(_ item: RollingOvertimeDraft) -> String {
        return lenientFloatPoolVarianceBucket(item.netExposure())
    }
}
