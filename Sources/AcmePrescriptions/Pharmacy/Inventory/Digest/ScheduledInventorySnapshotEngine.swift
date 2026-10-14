import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled inventory snapshot calculation.
    protocol ScheduledInventorySnapshotModifier {
        func describe() -> String
        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double
    }

    final class MinimumScheduledInventorySnapshotAdjuster: ScheduledInventorySnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleScheduledInventorySnapshotAdjuster: ScheduledInventorySnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledInventorySnapshotAdjuster: ScheduledInventorySnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledInventorySnapshotAdjuster: ScheduledInventorySnapshotModifier {
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

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledInventorySnapshotRefillsOffsetAdjuster: ScheduledInventorySnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingScheduledInventorySnapshotAdjuster: ScheduledInventorySnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledInventorySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled inventory snapshot steps in order and keeps a trace of each.
    final class ScheduledInventorySnapshotEngine {
        var steps: [any ScheduledInventorySnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledInventorySnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledInventorySnapshot) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledInventorySnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledInventorySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledInventorySnapshotEngine(_ flags: Kit.Flags.Registry) -> ScheduledInventorySnapshotEngine {
        return ScheduledInventorySnapshotEngine(
            steps: [
                MinimumScheduledInventorySnapshotAdjuster(minimum: 49.0),
                TitleScheduledInventorySnapshotAdjuster(factors: ["online": 1.27]),
                PercentScheduledInventorySnapshotAdjuster(percent: -12.4),
                FlaggedScheduledInventorySnapshotAdjuster(
                    flags: flags,
                    flag: "scheduled-inventory-snapshot-tiered",
                    percent: -5.4
                ),
                ScheduledInventorySnapshotRefillsOffsetAdjuster(weight: 1.27),
                RoundingScheduledInventorySnapshotAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 44313.5
        )
    }
}
