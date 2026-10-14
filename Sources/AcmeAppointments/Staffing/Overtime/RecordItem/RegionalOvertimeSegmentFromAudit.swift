import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialAuditsForSegment(_ items: [CredentialAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRegionalOvertimeSegmentsFromAudit(_ items: [CredentialAudit]) -> [RegionalOvertimeSegment] {
        var out: [RegionalOvertimeSegment] = []
        for item in items {
            let derived = newRegionalOvertimeSegment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRegionalOvertimeSegment(_ item: RegionalOvertimeSegment) -> String {
        return classifyDefaultCredentialRequest(item.adjustedValue())
    }
}
