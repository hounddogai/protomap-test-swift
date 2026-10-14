import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient dispense metric calculation.
    protocol LenientDispenseMetricStep {
        func describe() -> String
        func adjust(_ item: LenientDispenseMetric, value: Double) -> Double
    }

    final class LenientDispenseMetricAmountOffsetAdjuster: LenientDispenseMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: LenientDispenseMetric, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredLenientDispenseMetricAdjuster: LenientDispenseMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDispenseMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLenientDispenseMetricAdjuster: LenientDispenseMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDispenseMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLenientDispenseMetricAdjuster: LenientDispenseMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientDispenseMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient dispense metric steps in order and keeps a trace of each.
    final class LenientDispenseMetricEngine {
        var steps: [any LenientDispenseMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDispenseMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientDispenseMetric) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDispenseMetricStep = steps[index]
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

        func evaluateAll(_ items: [LenientDispenseMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientDispenseMetricEngine() -> LenientDispenseMetricEngine {
        return LenientDispenseMetricEngine(
            steps: [
                LenientDispenseMetricAmountOffsetAdjuster(weight: 1.44),
                TieredLenientDispenseMetricAdjuster(bounds: [8249.0, 8660.0], rates: [1.1, 0.88]),
                RoundingLenientDispenseMetricAdjuster(step: 0.1),
                PercentLenientDispenseMetricAdjuster(percent: -19.6),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 81628.5
        )
    }
}
