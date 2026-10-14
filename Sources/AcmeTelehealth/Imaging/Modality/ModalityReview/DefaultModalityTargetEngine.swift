import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default modality target calculation.
    protocol DefaultModalityTargetAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultModalityTarget, value: Double) -> Double
    }

    final class DefaultModalityTargetSequenceOffsetAdjuster: DefaultModalityTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DefaultModalityTarget, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingDefaultModalityTargetAdjuster: DefaultModalityTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultModalityTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultModalityTargetAdjuster: DefaultModalityTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultModalityTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultModalityTargetAdjuster: DefaultModalityTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultModalityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default modality target steps in order and keeps a trace of each.
    final class DefaultModalityTargetEngine {
        var steps: [any DefaultModalityTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultModalityTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultModalityTarget) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultModalityTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultModalityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultModalityTargetEngine() -> DefaultModalityTargetEngine {
        return DefaultModalityTargetEngine(
            steps: [
                DefaultModalityTargetSequenceOffsetAdjuster(weight: 0.12),
                RoundingDefaultModalityTargetAdjuster(step: 1.0),
                MinimumDefaultModalityTargetAdjuster(minimum: 14.9),
                TieredDefaultModalityTargetAdjuster(bounds: [211.0, 2729.0], rates: [1.13, 0.8]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 35059.1
        )
    }
}
