import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel checkpoint calculation.
    protocol PanelCheckpointFactor {
        func describe() -> String
        func adjust(_ item: PanelCheckpoint, value: Double) -> Double
    }

    final class PanelCheckpointWeightOffsetAdjuster: PanelCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedPanelCheckpointAdjuster: PanelCheckpointFactor {
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

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPanelCheckpointAdjuster: PanelCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPanelCheckpointAdjuster: PanelCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPanelCheckpointAdjuster: PanelCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPanelCheckpointAdjuster: PanelCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel checkpoint steps in order and keeps a trace of each.
    final class PanelCheckpointEngine {
        var steps: [any PanelCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelCheckpoint) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelCheckpointFactor = steps[index]
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

        func evaluateAll(_ items: [PanelCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelCheckpointEngine(_ flags: Kit.Flags.Registry) -> PanelCheckpointEngine {
        return PanelCheckpointEngine(
            steps: [
                PanelCheckpointWeightOffsetAdjuster(weight: 0.15),
                FlaggedPanelCheckpointAdjuster(flags: flags, flag: "panel-checkpoint-global", percent: 5.7),
                MinimumPanelCheckpointAdjuster(minimum: 32.8),
                CapPanelCheckpointAdjuster(cap: 12967.0),
                RoundingPanelCheckpointAdjuster(step: 1.0),
                PercentPanelCheckpointAdjuster(percent: -14.2),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 21101.6
        )
    }
}
