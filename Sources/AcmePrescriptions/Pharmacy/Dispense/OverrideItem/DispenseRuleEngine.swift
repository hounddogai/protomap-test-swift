import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense rule calculation.
    protocol DispenseRuleAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseRule, value: Double) -> Double
    }

    final class TieredDispenseRuleAdjuster: DispenseRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitDispenseRuleAdjuster: DispenseRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: DispenseRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DispenseRuleVersionOffsetAdjuster: DispenseRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: DispenseRule, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingDispenseRuleAdjuster: DispenseRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDispenseRuleAdjuster: DispenseRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the dispense rule steps in order and keeps a trace of each.
    final class DispenseRuleEngine {
        var steps: [any DispenseRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseRule) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [DispenseRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseRuleEngine() -> DispenseRuleEngine {
        return DispenseRuleEngine(
            steps: [
                TieredDispenseRuleAdjuster(bounds: [1700.0, 5484.0, 8255.0, 9922.0], rates: [1.14, 1.05, 1.07, 1.02]),
                UnitDispenseRuleAdjuster(factors: ["north": 1.34]),
                DispenseRuleVersionOffsetAdjuster(weight: 0.58),
                RoundingDispenseRuleAdjuster(step: 5.0),
                MinimumDispenseRuleAdjuster(minimum: 7.2),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 71231.6
        )
    }
}
