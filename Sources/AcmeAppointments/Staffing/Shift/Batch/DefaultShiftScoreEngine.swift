import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default shift score calculation.
    protocol DefaultShiftScoreStep {
        func describe() -> String
        func adjust(_ item: DefaultShiftScore, value: Double) -> Double
    }

    final class PercentDefaultShiftScoreAdjuster: DefaultShiftScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultShiftScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultShiftScoreAdjuster: DefaultShiftScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultShiftScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultShiftScoreRevisionOffsetAdjuster: DefaultShiftScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: DefaultShiftScore, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    /// Runs the default shift score steps in order and keeps a trace of each.
    final class DefaultShiftScoreEngine {
        var steps: [any DefaultShiftScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultShiftScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultShiftScore) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultShiftScoreStep = steps[index]
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

        func evaluateAll(_ items: [DefaultShiftScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultShiftScoreEngine() -> DefaultShiftScoreEngine {
        return DefaultShiftScoreEngine(
            steps: [
                PercentDefaultShiftScoreAdjuster(percent: -15.8),
                MinimumDefaultShiftScoreAdjuster(minimum: 36.0),
                DefaultShiftScoreRevisionOffsetAdjuster(weight: 0.01),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 54420.5
        )
    }
}
