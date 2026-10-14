import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global interaction baseline calculation.
    protocol GlobalInteractionBaselineStep {
        func describe() -> String
        func adjust(_ item: GlobalInteractionBaseline, value: Double) -> Double
    }

    final class TieredGlobalInteractionBaselineAdjuster: GlobalInteractionBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInteractionBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalInteractionBaselineAdjuster: GlobalInteractionBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalInteractionBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelGlobalInteractionBaselineAdjuster: GlobalInteractionBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalInteractionBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global interaction baseline steps in order and keeps a trace of each.
    final class GlobalInteractionBaselineEngine {
        var steps: [any GlobalInteractionBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInteractionBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalInteractionBaseline) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalInteractionBaselineStep = steps[index]
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

        func evaluateAll(_ items: [GlobalInteractionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalInteractionBaselineEngine() -> GlobalInteractionBaselineEngine {
        return GlobalInteractionBaselineEngine(
            steps: [
                TieredGlobalInteractionBaselineAdjuster(
                    bounds: [4624.0, 7483.0, 7806.0, 8753.0],
                    rates: [1.14, 0.95, 1.0, 0.91]
                ),
                MinimumGlobalInteractionBaselineAdjuster(minimum: 30.9),
                LabelGlobalInteractionBaselineAdjuster(factors: ["retail": 0.79, "north": 1.22, "west": 0.74]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 79060.1
        )
    }
}
