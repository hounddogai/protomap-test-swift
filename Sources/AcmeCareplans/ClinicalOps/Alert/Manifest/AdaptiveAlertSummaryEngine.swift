import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive alert summary calculation.
    protocol AdaptiveAlertSummaryModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveAlertSummary, value: Double) -> Double
    }

    final class TieredAdaptiveAlertSummaryAdjuster: AdaptiveAlertSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveAlertSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveAlertSummaryAmountOffsetAdjuster: AdaptiveAlertSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AdaptiveAlertSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingAdaptiveAlertSummaryAdjuster: AdaptiveAlertSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveAlertSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive alert summary steps in order and keeps a trace of each.
    final class AdaptiveAlertSummaryEngine {
        var steps: [any AdaptiveAlertSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAlertSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveAlertSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveAlertSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveAlertSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAlertSummaryEngine() -> AdaptiveAlertSummaryEngine {
        return AdaptiveAlertSummaryEngine(
            steps: [
                TieredAdaptiveAlertSummaryAdjuster(
                    bounds: [1847.0, 3277.0, 4524.0, 5270.0],
                    rates: [1.07, 1.14, 0.86, 0.86]
                ),
                AdaptiveAlertSummaryAmountOffsetAdjuster(weight: 1.25),
                RoundingAdaptiveAlertSummaryAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 64707.9
        )
    }
}
