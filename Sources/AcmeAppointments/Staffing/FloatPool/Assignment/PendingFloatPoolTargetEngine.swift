import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending float pool target calculation.
    protocol PendingFloatPoolTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double
    }

    final class PercentPendingFloatPoolTargetAdjuster: PendingFloatPoolTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingFloatPoolTargetDiscountOffsetAdjuster: PendingFloatPoolTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingPendingFloatPoolTargetAdjuster: PendingFloatPoolTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPendingFloatPoolTargetAdjuster: PendingFloatPoolTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPendingFloatPoolTargetAdjuster: PendingFloatPoolTargetAdjuster {
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

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingFloatPoolTargetAdjuster: PendingFloatPoolTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingFloatPoolTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending float pool target steps in order and keeps a trace of each.
    final class PendingFloatPoolTargetEngine {
        var steps: [any PendingFloatPoolTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFloatPoolTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingFloatPoolTarget) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFloatPoolTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingFloatPoolTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingFloatPoolTargetEngine(_ flags: Kit.Flags.Registry) -> PendingFloatPoolTargetEngine {
        return PendingFloatPoolTargetEngine(
            steps: [
                PercentPendingFloatPoolTargetAdjuster(percent: -13.5),
                PendingFloatPoolTargetDiscountOffsetAdjuster(weight: 1.53),
                RoundingPendingFloatPoolTargetAdjuster(step: 0.5),
                MinimumPendingFloatPoolTargetAdjuster(minimum: 2.8),
                FlaggedPendingFloatPoolTargetAdjuster(
                    flags: flags,
                    flag: "pending-float-pool-target-rolling",
                    percent: 8.6
                ),
                TieredPendingFloatPoolTargetAdjuster(bounds: [1481.0, 3572.0, 7365.0], rates: [0.92, 0.88, 0.91]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 93386.3
        )
    }
}
