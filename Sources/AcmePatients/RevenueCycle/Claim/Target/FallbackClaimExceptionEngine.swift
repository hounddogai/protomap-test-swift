import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback claim exception calculation.
    protocol FallbackClaimExceptionModifier {
        func describe() -> String
        func adjust(_ item: FallbackClaimException, value: Double) -> Double
    }

    final class FlaggedFallbackClaimExceptionAdjuster: FallbackClaimExceptionModifier {
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

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackClaimExceptionPriorityOffsetAdjuster: FallbackClaimExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumFallbackClaimExceptionAdjuster: FallbackClaimExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackClaimExceptionAdjuster: FallbackClaimExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackClaimExceptionAdjuster: FallbackClaimExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelFallbackClaimExceptionAdjuster: FallbackClaimExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FallbackClaimException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback claim exception steps in order and keeps a trace of each.
    final class FallbackClaimExceptionEngine {
        var steps: [any FallbackClaimExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackClaimExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackClaimException) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackClaimExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackClaimException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackClaimExceptionEngine(_ flags: Kit.Flags.Registry) -> FallbackClaimExceptionEngine {
        return FallbackClaimExceptionEngine(
            steps: [
                FlaggedFallbackClaimExceptionAdjuster(
                    flags: flags,
                    flag: "fallback-claim-exception-fallback",
                    percent: -6.4
                ),
                FallbackClaimExceptionPriorityOffsetAdjuster(weight: 1.09),
                MinimumFallbackClaimExceptionAdjuster(minimum: 36.8),
                CapFallbackClaimExceptionAdjuster(cap: 27586.0),
                RoundingFallbackClaimExceptionAdjuster(step: 0.25),
                LabelFallbackClaimExceptionAdjuster(factors: ["online": 1.26, "retail": 1.4, "central": 0.86]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 8363.5
        )
    }
}
