import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict denial target calculation.
    protocol StrictDenialTargetFactor {
        func describe() -> String
        func adjust(_ item: StrictDenialTarget, value: Double) -> Double
    }

    final class TieredStrictDenialTargetAdjuster: StrictDenialTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictDenialTargetAdjuster: StrictDenialTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStrictDenialTargetAdjuster: StrictDenialTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictDenialTargetAdjuster: StrictDenialTargetFactor {
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

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleStrictDenialTargetAdjuster: StrictDenialTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictDenialTargetAdjuster: StrictDenialTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictDenialTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict denial target steps in order and keeps a trace of each.
    final class StrictDenialTargetEngine {
        var steps: [any StrictDenialTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDenialTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictDenialTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictDenialTargetFactor = steps[index]
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

        func evaluateAll(_ items: [StrictDenialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictDenialTargetEngine(_ flags: Kit.Flags.Registry) -> StrictDenialTargetEngine {
        return StrictDenialTargetEngine(
            steps: [
                TieredStrictDenialTargetAdjuster(bounds: [116.0, 1775.0, 4727.0], rates: [1.19, 1.12, 1.1]),
                RoundingStrictDenialTargetAdjuster(step: 1.0),
                MinimumStrictDenialTargetAdjuster(minimum: 25.7),
                FlaggedStrictDenialTargetAdjuster(flags: flags, flag: "strict-denial-target-seasonal", percent: -6.5),
                LocaleStrictDenialTargetAdjuster(factors: ["south": 1.18, "west": 1.38, "east": 0.97]),
                PercentStrictDenialTargetAdjuster(percent: -24.5),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 83516.8
        )
    }
}
