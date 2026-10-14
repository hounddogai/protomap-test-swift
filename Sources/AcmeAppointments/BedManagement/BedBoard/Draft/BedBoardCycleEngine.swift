import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board cycle calculation.
    protocol BedBoardCycleAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardCycle, value: Double) -> Double
    }

    final class MinimumBedBoardCycleAdjuster: BedBoardCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BedBoardCycleCeilingOffsetAdjuster: BedBoardCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: BedBoardCycle, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedBedBoardCycleAdjuster: BedBoardCycleAdjuster {
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

        func adjust(_ item: BedBoardCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionBedBoardCycleAdjuster: BedBoardCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: BedBoardCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentBedBoardCycleAdjuster: BedBoardCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board cycle steps in order and keeps a trace of each.
    final class BedBoardCycleEngine {
        var steps: [any BedBoardCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardCycle) -> Double {
            var current = item.projectedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [BedBoardCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardCycleEngine(_ flags: Kit.Flags.Registry) -> BedBoardCycleEngine {
        return BedBoardCycleEngine(
            steps: [
                MinimumBedBoardCycleAdjuster(minimum: 27.6),
                BedBoardCycleCeilingOffsetAdjuster(weight: 0.77),
                FlaggedBedBoardCycleAdjuster(flags: flags, flag: "bed-board-cycle-capped", percent: -5.0),
                RegionBedBoardCycleAdjuster(factors: ["west": 1.0]),
                PercentBedBoardCycleAdjuster(percent: 7.1),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 21962.7
        )
    }
}
