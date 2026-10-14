import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board snapshot calculation.
    protocol BedBoardSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double
    }

    final class PercentBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
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

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBedBoardSnapshotAdjuster: BedBoardSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board snapshot steps in order and keeps a trace of each.
    final class BedBoardSnapshotEngine {
        var steps: [any BedBoardSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardSnapshot) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [BedBoardSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardSnapshotEngine(_ flags: Kit.Flags.Registry) -> BedBoardSnapshotEngine {
        return BedBoardSnapshotEngine(
            steps: [
                PercentBedBoardSnapshotAdjuster(percent: 22.1),
                CapBedBoardSnapshotAdjuster(cap: 37805.0),
                MinimumBedBoardSnapshotAdjuster(minimum: 26.8),
                FlaggedBedBoardSnapshotAdjuster(flags: flags, flag: "bed-board-snapshot-adaptive", percent: 4.2),
                NameBedBoardSnapshotAdjuster(factors: ["west": 1.35, "online": 1.13]),
                RoundingBedBoardSnapshotAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 53166.3
        )
    }
}
