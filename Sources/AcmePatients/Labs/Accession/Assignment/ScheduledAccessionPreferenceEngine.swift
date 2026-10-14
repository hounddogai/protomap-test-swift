import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled accession preference calculation.
    protocol ScheduledAccessionPreferenceModifier {
        func describe() -> String
        func adjust(_ item: ScheduledAccessionPreference, value: Double) -> Double
    }

    final class MinimumScheduledAccessionPreferenceAdjuster: ScheduledAccessionPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAccessionPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledAccessionPreferenceAdjuster: ScheduledAccessionPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAccessionPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledAccessionPreferenceAdjuster: ScheduledAccessionPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAccessionPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled accession preference steps in order and keeps a trace of each.
    final class ScheduledAccessionPreferenceEngine {
        var steps: [any ScheduledAccessionPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAccessionPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledAccessionPreference) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAccessionPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledAccessionPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledAccessionPreferenceEngine() -> ScheduledAccessionPreferenceEngine {
        return ScheduledAccessionPreferenceEngine(
            steps: [
                MinimumScheduledAccessionPreferenceAdjuster(minimum: 17.9),
                RoundingScheduledAccessionPreferenceAdjuster(step: 0.1),
                PercentScheduledAccessionPreferenceAdjuster(percent: 13.8),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 33066.6
        )
    }
}
