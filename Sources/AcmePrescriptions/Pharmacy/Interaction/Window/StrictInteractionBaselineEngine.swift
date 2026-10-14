import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict interaction baseline calculation.
    protocol StrictInteractionBaselineModifier {
        func describe() -> String
        func adjust(_ item: StrictInteractionBaseline, value: Double) -> Double
    }

    final class PercentStrictInteractionBaselineAdjuster: StrictInteractionBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictInteractionBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictInteractionBaselineAdjuster: StrictInteractionBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictInteractionBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictInteractionBaselineAdjuster: StrictInteractionBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictInteractionBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict interaction baseline steps in order and keeps a trace of each.
    final class StrictInteractionBaselineEngine {
        var steps: [any StrictInteractionBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInteractionBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictInteractionBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictInteractionBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [StrictInteractionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictInteractionBaselineEngine() -> StrictInteractionBaselineEngine {
        return StrictInteractionBaselineEngine(
            steps: [
                PercentStrictInteractionBaselineAdjuster(percent: 6.4),
                TieredStrictInteractionBaselineAdjuster(
                    bounds: [687.0, 5144.0, 5235.0, 6435.0],
                    rates: [0.88, 0.82, 1.19, 0.83]
                ),
                RoundingStrictInteractionBaselineAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 17077.3
        )
    }
}
