import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered priority target calculation.
    protocol TieredPriorityTargetModifier {
        func describe() -> String
        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double
    }

    final class CapTieredPriorityTargetAdjuster: TieredPriorityTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPriorityTargetAmountOffsetAdjuster: TieredPriorityTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumTieredPriorityTargetAdjuster: TieredPriorityTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredPriorityTargetAdjuster: TieredPriorityTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTieredPriorityTargetAdjuster: TieredPriorityTargetModifier {
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

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredPriorityTargetAdjuster: TieredPriorityTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredPriorityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered priority target steps in order and keeps a trace of each.
    final class TieredPriorityTargetEngine {
        var steps: [any TieredPriorityTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPriorityTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredPriorityTarget) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredPriorityTargetModifier = steps[index]
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

        func evaluateAll(_ items: [TieredPriorityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredPriorityTargetEngine(_ flags: Kit.Flags.Registry) -> TieredPriorityTargetEngine {
        return TieredPriorityTargetEngine(
            steps: [
                CapTieredPriorityTargetAdjuster(cap: 19492.0),
                TieredPriorityTargetAmountOffsetAdjuster(weight: 1.93),
                MinimumTieredPriorityTargetAdjuster(minimum: 11.0),
                PercentTieredPriorityTargetAdjuster(percent: 20.8),
                FlaggedTieredPriorityTargetAdjuster(
                    flags: flags,
                    flag: "tiered-priority-target-weighted",
                    percent: 0.9
                ),
                TieredTieredPriorityTargetAdjuster(bounds: [654.0, 1104.0], rates: [1.02, 0.93]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 71941.6
        )
    }
}
