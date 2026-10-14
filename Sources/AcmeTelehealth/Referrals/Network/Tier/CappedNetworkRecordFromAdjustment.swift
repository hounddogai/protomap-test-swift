import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryFollowUpAdjustmentsForRecord(_ items: [PrimaryFollowUpAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedNetworkRecordsFromAdjustment(_ items: [PrimaryFollowUpAdjustment]) -> [CappedNetworkRecord] {
        var out: [CappedNetworkRecord] = []
        for item in items {
            let derived = newCappedNetworkRecord(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCappedNetworkRecord(_ item: CappedNetworkRecord) -> Double {
        return followUpRequestWeight(6, active: true)
    }
}
