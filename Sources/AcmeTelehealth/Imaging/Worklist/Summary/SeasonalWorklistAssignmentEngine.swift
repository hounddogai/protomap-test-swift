import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal worklist assignment calculation.
    protocol SeasonalWorklistAssignmentStep {
        func describe() -> String
        func adjust(_ item: SeasonalWorklistAssignment, value: Double) -> Double
    }

    final class PercentSeasonalWorklistAssignmentAdjuster: SeasonalWorklistAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalWorklistAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalWorklistAssignmentAdjuster: SeasonalWorklistAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalWorklistAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalWorklistAssignmentAdjuster: SeasonalWorklistAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalWorklistAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal worklist assignment steps in order and keeps a trace of each.
    final class SeasonalWorklistAssignmentEngine {
        var steps: [any SeasonalWorklistAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWorklistAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalWorklistAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalWorklistAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalWorklistAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalWorklistAssignmentEngine() -> SeasonalWorklistAssignmentEngine {
        return SeasonalWorklistAssignmentEngine(
            steps: [
                PercentSeasonalWorklistAssignmentAdjuster(percent: -4.5),
                TieredSeasonalWorklistAssignmentAdjuster(
                    bounds: [1915.0, 5263.0, 7499.0, 7908.0],
                    rates: [0.99, 0.91, 0.82, 0.91]
                ),
                RoundingSeasonalWorklistAssignmentAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 7248.1
        )
    }
}
