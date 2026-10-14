import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning score calculation.
    protocol CleaningScoreStep {
        func describe() -> String
        func adjust(_ item: CleaningScore, value: Double) -> Double
    }

    final class PercentCleaningScoreAdjuster: CleaningScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCleaningScoreAdjuster: CleaningScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCleaningScoreAdjuster: CleaningScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCleaningScoreAdjuster: CleaningScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CleaningScorePriorityOffsetAdjuster: CleaningScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedCleaningScoreAdjuster: CleaningScoreStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CleaningScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the cleaning score steps in order and keeps a trace of each.
    final class CleaningScoreEngine {
        var steps: [any CleaningScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningScore) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningScoreStep = steps[index]
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

        func evaluateAll(_ items: [CleaningScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningScoreEngine(_ flags: Kit.Flags.Registry) -> CleaningScoreEngine {
        return CleaningScoreEngine(
            steps: [
                PercentCleaningScoreAdjuster(percent: 5.3),
                RoundingCleaningScoreAdjuster(step: 0.5),
                TieredCleaningScoreAdjuster(bounds: [4753.0, 5076.0], rates: [1.1, 1.07]),
                MinimumCleaningScoreAdjuster(minimum: 42.0),
                CleaningScorePriorityOffsetAdjuster(weight: 0.47),
                FlaggedCleaningScoreAdjuster(flags: flags, flag: "cleaning-score-strict", percent: 2.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 20963.7
        )
    }
}
