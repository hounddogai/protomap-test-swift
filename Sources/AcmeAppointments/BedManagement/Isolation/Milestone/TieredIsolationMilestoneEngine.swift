import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered isolation milestone calculation.
    protocol MilestoneTieredIsolationMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double
    }

    final class FlaggedTieredIsolationMilestoneAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
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

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionTieredIsolationMilestoneAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredIsolationMilestoneFloorValueOffsetAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingTieredIsolationMilestoneAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredIsolationMilestoneAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTieredIsolationMilestoneAdjuster: MilestoneTieredIsolationMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredIsolationMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered isolation milestone steps in order and keeps a trace of each.
    final class TieredIsolationMilestoneEngine {
        var steps: [any MilestoneTieredIsolationMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any MilestoneTieredIsolationMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredIsolationMilestone) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any MilestoneTieredIsolationMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredIsolationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredIsolationMilestoneEngine(_ flags: Kit.Flags.Registry) -> TieredIsolationMilestoneEngine {
        return TieredIsolationMilestoneEngine(
            steps: [
                FlaggedTieredIsolationMilestoneAdjuster(
                    flags: flags,
                    flag: "tiered-isolation-milestone-batched",
                    percent: 9.5
                ),
                RegionTieredIsolationMilestoneAdjuster(factors: ["retail": 1.2]),
                TieredIsolationMilestoneFloorValueOffsetAdjuster(weight: 1.39),
                RoundingTieredIsolationMilestoneAdjuster(step: 5.0),
                MinimumTieredIsolationMilestoneAdjuster(minimum: 49.4),
                TieredTieredIsolationMilestoneAdjuster(
                    bounds: [976.0, 2264.0, 5379.0, 5563.0],
                    rates: [0.94, 0.85, 0.91, 0.88]
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 84522.3
        )
    }
}
