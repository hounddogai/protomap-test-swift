import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility target calculation.
    protocol EligibilityTargetFactor {
        func describe() -> String
        func adjust(_ item: EligibilityTarget, value: Double) -> Double
    }

    final class PercentEligibilityTargetAdjuster: EligibilityTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class EligibilityTargetRatioOffsetAdjuster: EligibilityTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapEligibilityTargetAdjuster: EligibilityTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumEligibilityTargetAdjuster: EligibilityTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedEligibilityTargetAdjuster: EligibilityTargetFactor {
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

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilityTargetAdjuster: EligibilityTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the eligibility target steps in order and keeps a trace of each.
    final class EligibilityTargetEngine {
        var steps: [any EligibilityTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityTarget) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityTargetFactor = steps[index]
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

        func evaluateAll(_ items: [EligibilityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityTargetEngine(_ flags: Kit.Flags.Registry) -> EligibilityTargetEngine {
        return EligibilityTargetEngine(
            steps: [
                PercentEligibilityTargetAdjuster(percent: 7.2),
                EligibilityTargetRatioOffsetAdjuster(weight: 1.87),
                CapEligibilityTargetAdjuster(cap: 14318.0),
                MinimumEligibilityTargetAdjuster(minimum: 27.6),
                FlaggedEligibilityTargetAdjuster(flags: flags, flag: "eligibility-target-lenient", percent: 2.4),
                TieredEligibilityTargetAdjuster(bounds: [6041.0, 7052.0], rates: [0.94, 0.96]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 75567.7
        )
    }
}
