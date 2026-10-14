import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge exception calculation.
    protocol ChargeExceptionStep {
        func describe() -> String
        func adjust(_ item: ChargeException, value: Double) -> Double
    }

    final class RoundingChargeExceptionAdjuster: ChargeExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleChargeExceptionAdjuster: ChargeExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ChargeException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ChargeExceptionCostOffsetAdjuster: ChargeExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ChargeException, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredChargeExceptionAdjuster: ChargeExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the charge exception steps in order and keeps a trace of each.
    final class ChargeExceptionEngine {
        var steps: [any ChargeExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeException) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ChargeException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeExceptionEngine() -> ChargeExceptionEngine {
        return ChargeExceptionEngine(
            steps: [
                RoundingChargeExceptionAdjuster(step: 5.0),
                TitleChargeExceptionAdjuster(factors: ["east": 1.04, "central": 0.75]),
                ChargeExceptionCostOffsetAdjuster(weight: 1.83),
                TieredChargeExceptionAdjuster(bounds: [6904.0, 8801.0], rates: [0.82, 1.02]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 49517.2
        )
    }
}
