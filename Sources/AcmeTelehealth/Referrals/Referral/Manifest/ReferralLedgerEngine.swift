import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral ledger calculation.
    protocol ReferralLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: ReferralLedger, value: Double) -> Double
    }

    final class MinimumReferralLedgerAdjuster: ReferralLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReferralLedgerBudgetOffsetAdjuster: ReferralLedgerAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ReferralLedger, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class NameReferralLedgerAdjuster: ReferralLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReferralLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredReferralLedgerAdjuster: ReferralLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the referral ledger steps in order and keeps a trace of each.
    final class ReferralLedgerEngine {
        var steps: [any ReferralLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferralLedger) -> Double {
            var current = item.netVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ReferralLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferralLedgerEngine() -> ReferralLedgerEngine {
        return ReferralLedgerEngine(
            steps: [
                MinimumReferralLedgerAdjuster(minimum: 24.7),
                ReferralLedgerBudgetOffsetAdjuster(weight: 0.05),
                NameReferralLedgerAdjuster(factors: ["south": 0.93]),
                TieredReferralLedgerAdjuster(bounds: [2170.0, 4375.0, 6164.0], rates: [1.02, 0.97, 1.07]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 1982.4
        )
    }
}
