import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered order set cycle calculation.
    protocol TieredOrderSetCycleModifier {
        func describe() -> String
        func adjust(_ item: TieredOrderSetCycle, value: Double) -> Double
    }

    final class MinimumTieredOrderSetCycleAdjuster: TieredOrderSetCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOrderSetCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredOrderSetCycleAdjuster: TieredOrderSetCycleModifier {
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

        func adjust(_ item: TieredOrderSetCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredOrderSetCycleAdjuster: TieredOrderSetCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredOrderSetCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered order set cycle steps in order and keeps a trace of each.
    final class TieredOrderSetCycleEngine {
        var steps: [any TieredOrderSetCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOrderSetCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredOrderSetCycle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredOrderSetCycleModifier = steps[index]
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

        func evaluateAll(_ items: [TieredOrderSetCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredOrderSetCycleEngine(_ flags: Kit.Flags.Registry) -> TieredOrderSetCycleEngine {
        return TieredOrderSetCycleEngine(
            steps: [
                MinimumTieredOrderSetCycleAdjuster(minimum: 26.6),
                FlaggedTieredOrderSetCycleAdjuster(
                    flags: flags,
                    flag: "tiered-order-set-cycle-default",
                    percent: -4.3
                ),
                CapTieredOrderSetCycleAdjuster(cap: 2820.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 29894.5
        )
    }
}
