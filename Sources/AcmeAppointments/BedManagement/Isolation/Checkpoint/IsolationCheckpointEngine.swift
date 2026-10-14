import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation checkpoint calculation.
    protocol IsolationCheckpointModifier {
        func describe() -> String
        func adjust(_ item: IsolationCheckpoint, value: Double) -> Double
    }

    final class TieredIsolationCheckpointAdjuster: IsolationCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentIsolationCheckpointAdjuster: IsolationCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumIsolationCheckpointAdjuster: IsolationCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedIsolationCheckpointAdjuster: IsolationCheckpointModifier {
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

        func adjust(_ item: IsolationCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the isolation checkpoint steps in order and keeps a trace of each.
    final class IsolationCheckpointEngine {
        var steps: [any IsolationCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: IsolationCheckpoint) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [IsolationCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultIsolationCheckpointEngine(_ flags: Kit.Flags.Registry) -> IsolationCheckpointEngine {
        return IsolationCheckpointEngine(
            steps: [
                TieredIsolationCheckpointAdjuster(bounds: [4864.0, 9761.0], rates: [0.84, 1.05]),
                PercentIsolationCheckpointAdjuster(percent: 19.8),
                MinimumIsolationCheckpointAdjuster(minimum: 18.6),
                FlaggedIsolationCheckpointAdjuster(flags: flags, flag: "isolation-checkpoint-pending", percent: 3.6),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 74185.3
        )
    }
}
