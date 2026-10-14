import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession variance calculation.
    protocol AccessionVarianceModifier {
        func describe() -> String
        func adjust(_ item: AccessionVariance, value: Double) -> Double
    }

    final class PercentAccessionVarianceAdjuster: AccessionVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AccessionVarianceCopayOffsetAdjuster: AccessionVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: AccessionVariance, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumAccessionVarianceAdjuster: AccessionVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAccessionVarianceAdjuster: AccessionVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAccessionVarianceAdjuster: AccessionVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the accession variance steps in order and keeps a trace of each.
    final class AccessionVarianceEngine {
        var steps: [any AccessionVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AccessionVariance) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AccessionVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAccessionVarianceEngine() -> AccessionVarianceEngine {
        return AccessionVarianceEngine(
            steps: [
                PercentAccessionVarianceAdjuster(percent: -16.9),
                AccessionVarianceCopayOffsetAdjuster(weight: 1.82),
                MinimumAccessionVarianceAdjuster(minimum: 11.0),
                RoundingAccessionVarianceAdjuster(step: 1.0),
                TieredAccessionVarianceAdjuster(bounds: [3621.0, 6803.0, 7292.0], rates: [0.86, 0.84, 1.07]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 89794.8
        )
    }
}
