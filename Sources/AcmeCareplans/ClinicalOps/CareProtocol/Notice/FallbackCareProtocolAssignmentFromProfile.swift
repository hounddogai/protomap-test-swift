import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalHandoffProfilesForAssignment(_ items: [RegionalHandoffProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackCareProtocolAssignmentsFromProfile(_ items: [RegionalHandoffProfile]) -> [FallbackCareProtocolAssignment] {
        var out: [FallbackCareProtocolAssignment] = []
        for item in items {
            let derived = newFallbackCareProtocolAssignment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeFallbackCareProtocolAssignment(_ item: FallbackCareProtocolAssignment) -> String {
        return normalizeDefaultHandoffDraftCode(item.code)
    }
}
