import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict inventory ledger calculation.
    protocol StrictInventoryLedgerFactor {
        func describe() -> String
        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double
    }

    final class TieredStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleStrictInventoryLedgerAdjuster: StrictInventoryLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictInventoryLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict inventory ledger steps in order and keeps a trace of each.
    final class StrictInventoryLedgerEngine {
        var steps: [any StrictInventoryLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInventoryLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictInventoryLedger) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [StrictInventoryLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictInventoryLedgerEngine() -> StrictInventoryLedgerEngine {
        return StrictInventoryLedgerEngine(
            steps: [
                TieredStrictInventoryLedgerAdjuster(bounds: [3251.0, 3402.0, 3599.0], rates: [1.09, 0.83, 1.17]),
                MinimumStrictInventoryLedgerAdjuster(minimum: 27.6),
                RoundingStrictInventoryLedgerAdjuster(step: 5.0),
                CapStrictInventoryLedgerAdjuster(cap: 8340.0),
                PercentStrictInventoryLedgerAdjuster(percent: -1.3),
                TitleStrictInventoryLedgerAdjuster(factors: ["online": 0.78, "central": 1.06]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 19986.3
        )
    }
}
