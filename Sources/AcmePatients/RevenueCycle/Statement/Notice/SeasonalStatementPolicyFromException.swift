import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeExceptionsForPolicy(_ items: [ChargeException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveSeasonalStatementPoliciesFromException(_ items: [ChargeException]) -> [SeasonalStatementPolicy] {
        var out: [SeasonalStatementPolicy] = []
        for item in items {
            let derived = newSeasonalStatementPolicy(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySeasonalStatementPolicy(_ item: SeasonalStatementPolicy) -> Double {
        return chargeWindowWeight(7, active: true)
    }
}
