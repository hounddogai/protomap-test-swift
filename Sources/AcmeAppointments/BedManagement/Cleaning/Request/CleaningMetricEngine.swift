import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning metric calculation.
    protocol CleaningMetricFactor {
        func describe() -> String
        func adjust(_ item: CleaningMetric, value: Double) -> Double
    }

    final class CapCleaningMetricAdjuster: CleaningMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCleaningMetricAdjuster: CleaningMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryCleaningMetricAdjuster: CleaningMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CleaningMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the cleaning metric steps in order and keeps a trace of each.
    final class CleaningMetricEngine {
        var steps: [any CleaningMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningMetric) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningMetricFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningMetricEngine() -> CleaningMetricEngine {
        return CleaningMetricEngine(
            steps: [
                CapCleaningMetricAdjuster(cap: 48889.0),
                MinimumCleaningMetricAdjuster(minimum: 15.2),
                CountryCleaningMetricAdjuster(factors: ["online": 1.39, "west": 1.34]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 20034.7
        )
    }
}
