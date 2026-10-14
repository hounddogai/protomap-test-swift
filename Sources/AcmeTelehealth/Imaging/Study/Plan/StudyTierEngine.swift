import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study tier calculation.
    protocol StudyTierStep {
        func describe() -> String
        func adjust(_ item: StudyTier, value: Double) -> Double
    }

    final class RoundingStudyTierAdjuster: StudyTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStudyTierAdjuster: StudyTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyTierAdjuster: StudyTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStudyTierAdjuster: StudyTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStudyTierAdjuster: StudyTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStudyTierAdjuster: StudyTierStep {
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

        func adjust(_ item: StudyTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study tier steps in order and keeps a trace of each.
    final class StudyTierEngine {
        var steps: [any StudyTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyTier) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyTierStep = steps[index]
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

        func evaluateAll(_ items: [StudyTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyTierEngine(_ flags: Kit.Flags.Registry) -> StudyTierEngine {
        return StudyTierEngine(
            steps: [
                RoundingStudyTierAdjuster(step: 0.1),
                MinimumStudyTierAdjuster(minimum: 25.9),
                PercentStudyTierAdjuster(percent: 0.4),
                CapStudyTierAdjuster(cap: 19768.0),
                TieredStudyTierAdjuster(bounds: [241.0, 1079.0, 9277.0], rates: [0.89, 0.83, 0.97]),
                FlaggedStudyTierAdjuster(flags: flags, flag: "study-tier-primary", percent: 4.8),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 72797.9
        )
    }
}
