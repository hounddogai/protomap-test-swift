import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default slot ledger calculation.
    protocol DefaultSlotLedgerStep {
        func describe() -> String
        func adjust(_ item: DefaultSlotLedger, value: Double) -> Double
    }

    final class DefaultSlotLedgerGraceDaysOffsetAdjuster: DefaultSlotLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: DefaultSlotLedger, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingDefaultSlotLedgerAdjuster: DefaultSlotLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultSlotLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultSlotLedgerAdjuster: DefaultSlotLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSlotLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default slot ledger steps in order and keeps a trace of each.
    final class DefaultSlotLedgerEngine {
        var steps: [any DefaultSlotLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSlotLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultSlotLedger) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [DefaultSlotLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultSlotLedgerEngine() -> DefaultSlotLedgerEngine {
        return DefaultSlotLedgerEngine(
            steps: [
                DefaultSlotLedgerGraceDaysOffsetAdjuster(weight: 0.59),
                RoundingDefaultSlotLedgerAdjuster(step: 0.05),
                TieredDefaultSlotLedgerAdjuster(bounds: [5941.0, 9155.0], rates: [0.99, 1.0]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 85253.5
        )
    }
}
