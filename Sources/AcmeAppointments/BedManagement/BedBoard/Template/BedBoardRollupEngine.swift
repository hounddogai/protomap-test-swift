import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board rollup calculation.
    protocol BedBoardRollupFactor {
        func describe() -> String
        func adjust(_ item: BedBoardRollup, value: Double) -> Double
    }

    final class FacilityBedBoardRollupAdjuster: BedBoardRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBedBoardRollupAdjuster: BedBoardRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BedBoardRollupExpiresAtOffsetAdjuster: BedBoardRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredBedBoardRollupAdjuster: BedBoardRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBedBoardRollupAdjuster: BedBoardRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBedBoardRollupAdjuster: BedBoardRollupFactor {
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

        func adjust(_ item: BedBoardRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board rollup steps in order and keeps a trace of each.
    final class BedBoardRollupEngine {
        var steps: [any BedBoardRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardRollupFactor = steps[index]
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

        func evaluateAll(_ items: [BedBoardRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardRollupEngine(_ flags: Kit.Flags.Registry) -> BedBoardRollupEngine {
        return BedBoardRollupEngine(
            steps: [
                FacilityBedBoardRollupAdjuster(factors: ["east": 0.86, "west": 1.15, "north": 1.34]),
                RoundingBedBoardRollupAdjuster(step: 0.5),
                BedBoardRollupExpiresAtOffsetAdjuster(weight: 1.75),
                TieredBedBoardRollupAdjuster(bounds: [2583.0, 7389.0, 8864.0], rates: [1.13, 1.05, 1.0]),
                MinimumBedBoardRollupAdjuster(minimum: 17.0),
                FlaggedBedBoardRollupAdjuster(flags: flags, flag: "bed-board-rollup-rolling", percent: 2.8),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 92570.6
        )
    }
}
