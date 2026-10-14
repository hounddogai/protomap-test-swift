import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialVariancesForSegment(_ items: [CredentialVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveOvertimeSegmentsFromVariance(_ items: [CredentialVariance]) -> [OvertimeSegment] {
        var out: [OvertimeSegment] = []
        for item in items {
            let derived = newOvertimeSegment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignOvertimeSegment(_ item: OvertimeSegment) -> Double {
        return credentialBundleWeight(1, active: true)
    }
}
