import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning summary calculation.
    protocol CleaningSummaryFactor {
        func describe() -> String
        func adjust(_ item: CleaningSummary, value: Double) -> Double
    }

    final class RoundingCleaningSummaryAdjuster: CleaningSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CleaningSummaryCostOffsetAdjuster: CleaningSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CleaningSummary, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CountryCleaningSummaryAdjuster: CleaningSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CleaningSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCleaningSummaryAdjuster: CleaningSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the cleaning summary steps in order and keeps a trace of each.
    final class CleaningSummaryEngine {
        var steps: [any CleaningSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningSummary) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningSummaryEngine() -> CleaningSummaryEngine {
        return CleaningSummaryEngine(
            steps: [
                RoundingCleaningSummaryAdjuster(step: 0.05),
                CleaningSummaryCostOffsetAdjuster(weight: 0.69),
                CountryCleaningSummaryAdjuster(factors: ["north": 0.75, "retail": 0.89, "west": 1.29]),
                MinimumCleaningSummaryAdjuster(minimum: 38.4),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 87921.5
        )
    }
}
