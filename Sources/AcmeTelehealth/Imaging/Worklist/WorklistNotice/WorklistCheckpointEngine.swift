import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist checkpoint calculation.
    protocol WorklistCheckpointFactor {
        func describe() -> String
        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double
    }

    final class TieredWorklistCheckpointAdjuster: WorklistCheckpointFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWorklistCheckpointAdjuster: WorklistCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWorklistCheckpointAdjuster: WorklistCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWorklistCheckpointAdjuster: WorklistCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWorklistCheckpointAdjuster: WorklistCheckpointFactor {
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

        func adjust(_ item: WorklistCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist checkpoint steps in order and keeps a trace of each.
    final class WorklistCheckpointEngine {
        var steps: [any WorklistCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistCheckpoint) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [WorklistCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistCheckpointEngine(_ flags: Kit.Flags.Registry) -> WorklistCheckpointEngine {
        return WorklistCheckpointEngine(
            steps: [
                TieredWorklistCheckpointAdjuster(
                    bounds: [158.0, 999.0, 2972.0, 7815.0],
                    rates: [1.13, 0.95, 0.96, 0.92]
                ),
                RoundingWorklistCheckpointAdjuster(step: 0.05),
                PercentWorklistCheckpointAdjuster(percent: -13.1),
                MinimumWorklistCheckpointAdjuster(minimum: 10.0),
                FlaggedWorklistCheckpointAdjuster(flags: flags, flag: "worklist-checkpoint-strict", percent: -7.6),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 50206.4
        )
    }
}
