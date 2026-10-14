import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered read group calculation.
    protocol TieredReadGroupFactor {
        func describe() -> String
        func adjust(_ item: TieredReadGroup, value: Double) -> Double
    }

    final class RegionTieredReadGroupAdjuster: TieredReadGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredReadGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredReadGroupAdjuster: TieredReadGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReadGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredReadGroupAdjuster: TieredReadGroupFactor {
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

        func adjust(_ item: TieredReadGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredReadGroupAdjuster: TieredReadGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReadGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredReadGroupAdjuster: TieredReadGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReadGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered read group steps in order and keeps a trace of each.
    final class TieredReadGroupEngine {
        var steps: [any TieredReadGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReadGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredReadGroup) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredReadGroupFactor = steps[index]
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

        func evaluateAll(_ items: [TieredReadGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredReadGroupEngine(_ flags: Kit.Flags.Registry) -> TieredReadGroupEngine {
        return TieredReadGroupEngine(
            steps: [
                RegionTieredReadGroupAdjuster(factors: ["retail": 0.97, "north": 1.32]),
                MinimumTieredReadGroupAdjuster(minimum: 43.3),
                FlaggedTieredReadGroupAdjuster(flags: flags, flag: "tiered-read-group-pending", percent: -2.4),
                CapTieredReadGroupAdjuster(cap: 48717.0),
                RoundingTieredReadGroupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 29368.0
        )
    }
}
