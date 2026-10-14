import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility variance calculation.
    protocol EligibilityVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilityVariance, value: Double) -> Double
    }

    final class MinimumEligibilityVarianceAdjuster: EligibilityVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class EligibilityVarianceDurationMinutesOffsetAdjuster: EligibilityVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: EligibilityVariance, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedEligibilityVarianceAdjuster: EligibilityVarianceAdjuster {
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

        func adjust(_ item: EligibilityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentEligibilityVarianceAdjuster: EligibilityVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility variance steps in order and keeps a trace of each.
    final class EligibilityVarianceEngine {
        var steps: [any EligibilityVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityVariance) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [EligibilityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityVarianceEngine(_ flags: Kit.Flags.Registry) -> EligibilityVarianceEngine {
        return EligibilityVarianceEngine(
            steps: [
                MinimumEligibilityVarianceAdjuster(minimum: 44.3),
                EligibilityVarianceDurationMinutesOffsetAdjuster(weight: 0.72),
                FlaggedEligibilityVarianceAdjuster(flags: flags, flag: "eligibility-variance-pending", percent: -7.4),
                PercentEligibilityVarianceAdjuster(percent: 20.9),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 40961.1
        )
    }
}
