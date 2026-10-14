import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialMappingsForSegment(_ items: [CredentialMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func derivePrimaryOvertimeSegmentsFromMapping(_ items: [CredentialMapping]) -> [PrimaryOvertimeSegment] {
        var out: [PrimaryOvertimeSegment] = []
        for item in items {
            let derived = newPrimaryOvertimeSegment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryOvertimeSegment(_ item: PrimaryOvertimeSegment) -> String {
        return normalizeCredentialPolicyCode(item.code)
    }
}
