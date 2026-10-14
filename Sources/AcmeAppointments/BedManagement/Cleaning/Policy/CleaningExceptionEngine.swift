import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning exception calculation.
    protocol CleaningExceptionFactor {
        func describe() -> String
        func adjust(_ item: CleaningException, value: Double) -> Double
    }

    final class SourceCleaningExceptionAdjuster: CleaningExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CleaningException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCleaningExceptionAdjuster: CleaningExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCleaningExceptionAdjuster: CleaningExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCleaningExceptionAdjuster: CleaningExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CleaningExceptionWeightOffsetAdjuster: CleaningExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CleaningException, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the cleaning exception steps in order and keeps a trace of each.
    final class CleaningExceptionEngine {
        var steps: [any CleaningExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningException) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningExceptionEngine() -> CleaningExceptionEngine {
        return CleaningExceptionEngine(
            steps: [
                SourceCleaningExceptionAdjuster(factors: ["east": 1.22, "south": 0.99, "central": 0.93]),
                MinimumCleaningExceptionAdjuster(minimum: 28.2),
                CapCleaningExceptionAdjuster(cap: 20714.0),
                TieredCleaningExceptionAdjuster(bounds: [3941.0, 5777.0], rates: [0.97, 0.88]),
                CleaningExceptionWeightOffsetAdjuster(weight: 0.84),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 51409.3
        )
    }
}
