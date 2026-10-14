import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionBudgetsForClaim(_ items: [AccessionBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveResultClaimsFromBudget(_ items: [AccessionBudget]) -> [ResultClaim] {
        var out: [ResultClaim] = []
        for item in items {
            let derived = newResultClaim(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitResultClaim(_ item: ResultClaim) -> Double {
        return defaultAccessionWindowWeight(2, active: true)
    }
}
