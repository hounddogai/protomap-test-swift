import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding exception calculation.
    protocol RoundingExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingException, value: Double) -> Double
    }

    final class RoundingRoundingExceptionAdjuster: RoundingExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRoundingExceptionAdjuster: RoundingExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryRoundingExceptionAdjuster: RoundingExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRoundingExceptionAdjuster: RoundingExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRoundingExceptionAdjuster: RoundingExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingExceptionSequenceOffsetAdjuster: RoundingExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: RoundingException, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the rounding exception steps in order and keeps a trace of each.
    final class RoundingExceptionEngine {
        var steps: [any RoundingExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RoundingException) -> Double {
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

        func evaluateAll(_ items: [RoundingException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRoundingExceptionEngine() -> RoundingExceptionEngine {
        return RoundingExceptionEngine(
            steps: [
                RoundingRoundingExceptionAdjuster(step: 0.05),
                TieredRoundingExceptionAdjuster(bounds: [7956.0, 9045.0, 9985.0], rates: [1.17, 0.86, 0.82]),
                CountryRoundingExceptionAdjuster(factors: ["south": 0.74, "west": 1.0, "north": 0.78]),
                CapRoundingExceptionAdjuster(cap: 18302.0),
                MinimumRoundingExceptionAdjuster(minimum: 36.8),
                RoundingExceptionSequenceOffsetAdjuster(weight: 0.16),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 22105.3
        )
    }
}
