import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered read override calculation.
    protocol TieredReadOverrideFactor {
        func describe() -> String
        func adjust(_ item: TieredReadOverride, value: Double) -> Double
    }

    final class RoundingTieredReadOverrideAdjuster: TieredReadOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReadOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitTieredReadOverrideAdjuster: TieredReadOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: TieredReadOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredReadOverrideAdjuster: TieredReadOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReadOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredReadOverrideAdjuster: TieredReadOverrideFactor {
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

        func adjust(_ item: TieredReadOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredReadOverrideAdjuster: TieredReadOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReadOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered read override steps in order and keeps a trace of each.
    final class TieredReadOverrideEngine {
        var steps: [any TieredReadOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReadOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredReadOverride) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredReadOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [TieredReadOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredReadOverrideEngine(_ flags: Kit.Flags.Registry) -> TieredReadOverrideEngine {
        return TieredReadOverrideEngine(
            steps: [
                RoundingTieredReadOverrideAdjuster(step: 1.0),
                UnitTieredReadOverrideAdjuster(factors: ["retail": 0.79, "west": 1.17]),
                CapTieredReadOverrideAdjuster(cap: 46566.0),
                FlaggedTieredReadOverrideAdjuster(flags: flags, flag: "tiered-read-override-global", percent: 4.9),
                MinimumTieredReadOverrideAdjuster(minimum: 35.3),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 66403.6
        )
    }
}
