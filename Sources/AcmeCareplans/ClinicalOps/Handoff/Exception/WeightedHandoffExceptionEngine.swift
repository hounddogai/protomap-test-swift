import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted handoff exception calculation.
    protocol WeightedHandoffExceptionModifier {
        func describe() -> String
        func adjust(_ item: WeightedHandoffException, value: Double) -> Double
    }

    final class RoundingWeightedHandoffExceptionAdjuster: WeightedHandoffExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedHandoffException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedHandoffExceptionAdjuster: WeightedHandoffExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedHandoffException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedHandoffExceptionAdjuster: WeightedHandoffExceptionModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedHandoffException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedHandoffExceptionAdjuster: WeightedHandoffExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedHandoffException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted handoff exception steps in order and keeps a trace of each.
    final class WeightedHandoffExceptionEngine {
        var steps: [any WeightedHandoffExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedHandoffExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedHandoffException) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [WeightedHandoffException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedHandoffExceptionEngine() -> WeightedHandoffExceptionEngine {
        return WeightedHandoffExceptionEngine(
            steps: [
                RoundingWeightedHandoffExceptionAdjuster(step: 0.25),
                CapWeightedHandoffExceptionAdjuster(cap: 40785.0),
                TieredWeightedHandoffExceptionAdjuster(
                    bounds: [776.0, 4968.0, 7194.0, 9511.0],
                    rates: [1.16, 0.9, 0.82, 1.15]
                ),
                PercentWeightedHandoffExceptionAdjuster(percent: -6.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 82532.3
        )
    }
}
