import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary cycle calculation.
    protocol FormularyCycleModifier {
        func describe() -> String
        func adjust(_ item: FormularyCycle, value: Double) -> Double
    }

    final class RoundingFormularyCycleAdjuster: FormularyCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFormularyCycleAdjuster: FormularyCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFormularyCycleAdjuster: FormularyCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFormularyCycleAdjuster: FormularyCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary cycle steps in order and keeps a trace of each.
    final class FormularyCycleEngine {
        var steps: [any FormularyCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FormularyCycle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyCycleModifier = steps[index]
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

        func evaluateAll(_ items: [FormularyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFormularyCycleEngine() -> FormularyCycleEngine {
        return FormularyCycleEngine(
            steps: [
                RoundingFormularyCycleAdjuster(step: 1.0),
                MinimumFormularyCycleAdjuster(minimum: 37.1),
                PercentFormularyCycleAdjuster(percent: -12.5),
                TieredFormularyCycleAdjuster(bounds: [94.0, 1520.0, 5454.0, 9178.0], rates: [0.89, 1.18, 0.81, 1.16]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 39457.3
        )
    }
}
