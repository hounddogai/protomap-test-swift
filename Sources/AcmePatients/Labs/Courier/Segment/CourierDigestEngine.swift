import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier digest calculation.
    protocol CourierDigestAdjuster {
        func describe() -> String
        func adjust(_ item: CourierDigest, value: Double) -> Double
    }

    final class CategoryCourierDigestAdjuster: CourierDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CourierDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCourierDigestAdjuster: CourierDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCourierDigestAdjuster: CourierDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCourierDigestAdjuster: CourierDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier digest steps in order and keeps a trace of each.
    final class CourierDigestEngine {
        var steps: [any CourierDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CourierDigest) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [CourierDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCourierDigestEngine() -> CourierDigestEngine {
        return CourierDigestEngine(
            steps: [
                CategoryCourierDigestAdjuster(factors: ["east": 1.06, "north": 1.15, "central": 1.14]),
                TieredCourierDigestAdjuster(bounds: [1773.0, 8576.0, 8959.0], rates: [0.95, 0.95, 0.82]),
                RoundingCourierDigestAdjuster(step: 0.25),
                MinimumCourierDigestAdjuster(minimum: 2.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 37543.5
        )
    }
}
