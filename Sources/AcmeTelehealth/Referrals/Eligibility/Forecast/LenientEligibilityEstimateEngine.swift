import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient eligibility estimate calculation.
    protocol LenientEligibilityEstimateFactor {
        func describe() -> String
        func adjust(_ item: LenientEligibilityEstimate, value: Double) -> Double
    }

    final class FlaggedLenientEligibilityEstimateAdjuster: LenientEligibilityEstimateFactor {
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

        func adjust(_ item: LenientEligibilityEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientEligibilityEstimateAdjuster: LenientEligibilityEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientEligibilityEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientEligibilityEstimateAdjuster: LenientEligibilityEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientEligibilityEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient eligibility estimate steps in order and keeps a trace of each.
    final class LenientEligibilityEstimateEngine {
        var steps: [any LenientEligibilityEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientEligibilityEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientEligibilityEstimate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientEligibilityEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [LenientEligibilityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientEligibilityEstimateEngine(_ flags: Kit.Flags.Registry) -> LenientEligibilityEstimateEngine {
        return LenientEligibilityEstimateEngine(
            steps: [
                FlaggedLenientEligibilityEstimateAdjuster(
                    flags: flags,
                    flag: "lenient-eligibility-estimate-tiered",
                    percent: 8.1
                ),
                MinimumLenientEligibilityEstimateAdjuster(minimum: 13.8),
                RoundingLenientEligibilityEstimateAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 37035.2
        )
    }
}
