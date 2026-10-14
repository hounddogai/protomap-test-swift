import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance threshold calculation.
    protocol RemittanceThresholdModifier {
        func describe() -> String
        func adjust(_ item: RemittanceThreshold, value: Double) -> Double
    }

    final class TieredRemittanceThresholdAdjuster: RemittanceThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceThresholdAdjuster: RemittanceThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RemittanceThresholdDiscountOffsetAdjuster: RemittanceThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: RemittanceThreshold, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumRemittanceThresholdAdjuster: RemittanceThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance threshold steps in order and keeps a trace of each.
    final class RemittanceThresholdEngine {
        var steps: [any RemittanceThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceThreshold) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [RemittanceThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceThresholdEngine() -> RemittanceThresholdEngine {
        return RemittanceThresholdEngine(
            steps: [
                TieredRemittanceThresholdAdjuster(
                    bounds: [2051.0, 3033.0, 4275.0, 8555.0],
                    rates: [1.08, 1.16, 1.07, 1.0]
                ),
                RoundingRemittanceThresholdAdjuster(step: 0.1),
                RemittanceThresholdDiscountOffsetAdjuster(weight: 0.84),
                MinimumRemittanceThresholdAdjuster(minimum: 5.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 6296.0
        )
    }
}
