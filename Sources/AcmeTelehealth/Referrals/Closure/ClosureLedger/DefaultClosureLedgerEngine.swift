import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default closure ledger calculation.
    protocol DefaultClosureLedgerFactor {
        func describe() -> String
        func adjust(_ item: DefaultClosureLedger, value: Double) -> Double
    }

    final class RoundingDefaultClosureLedgerAdjuster: DefaultClosureLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultClosureLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDefaultClosureLedgerAdjuster: DefaultClosureLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultClosureLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultClosureLedgerAdjuster: DefaultClosureLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultClosureLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default closure ledger steps in order and keeps a trace of each.
    final class DefaultClosureLedgerEngine {
        var steps: [any DefaultClosureLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultClosureLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultClosureLedger) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultClosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultClosureLedgerEngine() -> DefaultClosureLedgerEngine {
        return DefaultClosureLedgerEngine(
            steps: [
                RoundingDefaultClosureLedgerAdjuster(step: 0.25),
                PercentDefaultClosureLedgerAdjuster(percent: -8.1),
                TieredDefaultClosureLedgerAdjuster(bounds: [4767.0, 6412.0], rates: [1.17, 1.15]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 97163.0
        )
    }
}
