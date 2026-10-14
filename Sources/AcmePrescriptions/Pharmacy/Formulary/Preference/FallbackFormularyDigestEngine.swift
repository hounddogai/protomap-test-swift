import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback formulary digest calculation.
    protocol FallbackFormularyDigestFactor {
        func describe() -> String
        func adjust(_ item: FallbackFormularyDigest, value: Double) -> Double
    }

    final class RoundingFallbackFormularyDigestAdjuster: FallbackFormularyDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackFormularyDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameFallbackFormularyDigestAdjuster: FallbackFormularyDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackFormularyDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackFormularyDigestAdjuster: FallbackFormularyDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackFormularyDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback formulary digest steps in order and keeps a trace of each.
    final class FallbackFormularyDigestEngine {
        var steps: [any FallbackFormularyDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFormularyDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackFormularyDigest) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackFormularyDigestFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackFormularyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackFormularyDigestEngine() -> FallbackFormularyDigestEngine {
        return FallbackFormularyDigestEngine(
            steps: [
                RoundingFallbackFormularyDigestAdjuster(step: 0.1),
                NameFallbackFormularyDigestAdjuster(factors: ["online": 0.95]),
                MinimumFallbackFormularyDigestAdjuster(minimum: 42.4),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 51905.7
        )
    }
}
