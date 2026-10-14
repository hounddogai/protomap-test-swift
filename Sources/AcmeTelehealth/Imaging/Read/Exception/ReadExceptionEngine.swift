import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read exception calculation.
    protocol ReadExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ReadException, value: Double) -> Double
    }

    final class RoundingReadExceptionAdjuster: ReadExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryReadExceptionAdjuster: ReadExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredReadExceptionAdjuster: ReadExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumReadExceptionAdjuster: ReadExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReadExceptionAdjuster: ReadExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ReadExceptionWeightOffsetAdjuster: ReadExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ReadException, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the read exception steps in order and keeps a trace of each.
    final class ReadExceptionEngine {
        var steps: [any ReadExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadException) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReadException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadExceptionEngine() -> ReadExceptionEngine {
        return ReadExceptionEngine(
            steps: [
                RoundingReadExceptionAdjuster(step: 1.0),
                CountryReadExceptionAdjuster(factors: ["online": 0.78, "retail": 0.97, "north": 1.03]),
                TieredReadExceptionAdjuster(bounds: [33.0, 530.0, 4931.0, 6840.0], rates: [0.81, 1.01, 1.06, 1.17]),
                MinimumReadExceptionAdjuster(minimum: 15.4),
                CapReadExceptionAdjuster(cap: 10948.0),
                ReadExceptionWeightOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 4998.7
        )
    }
}
