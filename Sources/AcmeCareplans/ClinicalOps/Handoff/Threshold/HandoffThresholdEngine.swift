import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff threshold calculation.
    protocol HandoffThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffThreshold, value: Double) -> Double
    }

    final class PercentHandoffThresholdAdjuster: HandoffThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumHandoffThresholdAdjuster: HandoffThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredHandoffThresholdAdjuster: HandoffThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the handoff threshold steps in order and keeps a trace of each.
    final class HandoffThresholdEngine {
        var steps: [any HandoffThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffThreshold) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffThresholdEngine() -> HandoffThresholdEngine {
        return HandoffThresholdEngine(
            steps: [
                PercentHandoffThresholdAdjuster(percent: 0.3),
                MinimumHandoffThresholdAdjuster(minimum: 3.9),
                TieredHandoffThresholdAdjuster(bounds: [814.0, 4972.0, 9824.0], rates: [1.1, 0.84, 1.1]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 23734.6
        )
    }
}
