import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeRecordsForTarget(_ items: [OvertimeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalCredentialTargetsFromRecord(_ items: [OvertimeRecord]) -> [SeasonalCredentialTarget] {
        var out: [SeasonalCredentialTarget] = []
        for item in items {
            let derived = newSeasonalCredentialTarget(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchSeasonalCredentialTarget(_ item: SeasonalCredentialTarget) -> Double {
        return scheduledOvertimeProposalWeight(9, active: true)
    }
}
