import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global task ledger calculation.
    protocol GlobalTaskLedgerModifier {
        func describe() -> String
        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double
    }

    final class RoundingGlobalTaskLedgerAdjuster: GlobalTaskLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryGlobalTaskLedgerAdjuster: GlobalTaskLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalTaskLedgerAdjuster: GlobalTaskLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalTaskLedgerAdjuster: GlobalTaskLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalTaskLedgerThresholdOffsetAdjuster: GlobalTaskLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumGlobalTaskLedgerAdjuster: GlobalTaskLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalTaskLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global task ledger steps in order and keeps a trace of each.
    final class GlobalTaskLedgerEngine {
        var steps: [any GlobalTaskLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalTaskLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalTaskLedger) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalTaskLedgerModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalTaskLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalTaskLedgerEngine() -> GlobalTaskLedgerEngine {
        return GlobalTaskLedgerEngine(
            steps: [
                RoundingGlobalTaskLedgerAdjuster(step: 0.05),
                CountryGlobalTaskLedgerAdjuster(factors: ["central": 1.35]),
                TieredGlobalTaskLedgerAdjuster(bounds: [1745.0, 6890.0, 7139.0], rates: [0.92, 0.91, 0.83]),
                PercentGlobalTaskLedgerAdjuster(percent: -2.7),
                GlobalTaskLedgerThresholdOffsetAdjuster(weight: 0.14),
                MinimumGlobalTaskLedgerAdjuster(minimum: 13.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 14236.6
        )
    }
}
