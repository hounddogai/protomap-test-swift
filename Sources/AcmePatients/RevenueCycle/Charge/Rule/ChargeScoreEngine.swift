import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge score calculation.
    protocol ChargeScoreAdjuster {
        func describe() -> String
        func adjust(_ item: ChargeScore, value: Double) -> Double
    }

    final class RoundingChargeScoreAdjuster: ChargeScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumChargeScoreAdjuster: ChargeScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredChargeScoreAdjuster: ChargeScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the charge score steps in order and keeps a trace of each.
    final class ChargeScoreEngine {
        var steps: [any ChargeScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeScore) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ChargeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeScoreEngine() -> ChargeScoreEngine {
        return ChargeScoreEngine(
            steps: [
                RoundingChargeScoreAdjuster(step: 1.0),
                MinimumChargeScoreAdjuster(minimum: 5.8),
                TieredChargeScoreAdjuster(bounds: [395.0, 9239.0], rates: [1.03, 1.13]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 56972.1
        )
    }
}
