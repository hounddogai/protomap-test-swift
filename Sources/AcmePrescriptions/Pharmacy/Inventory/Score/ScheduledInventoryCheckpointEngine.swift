import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled inventory checkpoint calculation.
    protocol ScheduledInventoryCheckpointStep {
        func describe() -> String
        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double
    }

    final class RoundingScheduledInventoryCheckpointAdjuster: ScheduledInventoryCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledInventoryCheckpointAdjuster: ScheduledInventoryCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledInventoryCheckpointAdjuster: ScheduledInventoryCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledInventoryCheckpointAdjuster: ScheduledInventoryCheckpointStep {
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

        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledInventoryCheckpointPriorityOffsetAdjuster: ScheduledInventoryCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ScheduledInventoryCheckpoint, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the scheduled inventory checkpoint steps in order and keeps a trace of each.
    final class ScheduledInventoryCheckpointEngine {
        var steps: [any ScheduledInventoryCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledInventoryCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledInventoryCheckpoint) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ScheduledInventoryCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledInventoryCheckpointEngine(_ flags: Kit.Flags.Registry) -> ScheduledInventoryCheckpointEngine {
        return ScheduledInventoryCheckpointEngine(
            steps: [
                RoundingScheduledInventoryCheckpointAdjuster(step: 1.0),
                PercentScheduledInventoryCheckpointAdjuster(percent: -12.3),
                CapScheduledInventoryCheckpointAdjuster(cap: 19708.0),
                FlaggedScheduledInventoryCheckpointAdjuster(
                    flags: flags,
                    flag: "scheduled-inventory-checkpoint-rolling",
                    percent: -0.3
                ),
                ScheduledInventoryCheckpointPriorityOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 92722.5
        )
    }
}
