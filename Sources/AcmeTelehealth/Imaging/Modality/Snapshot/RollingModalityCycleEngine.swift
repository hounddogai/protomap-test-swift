import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling modality cycle calculation.
    protocol RollingModalityCycleFactor {
        func describe() -> String
        func adjust(_ item: RollingModalityCycle, value: Double) -> Double
    }

    final class TieredRollingModalityCycleAdjuster: RollingModalityCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingModalityCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingModalityCycleAdjuster: RollingModalityCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingModalityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingModalityCycleAdjuster: RollingModalityCycleFactor {
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

        func adjust(_ item: RollingModalityCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling modality cycle steps in order and keeps a trace of each.
    final class RollingModalityCycleEngine {
        var steps: [any RollingModalityCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingModalityCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingModalityCycle) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingModalityCycleFactor = steps[index]
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

        func evaluateAll(_ items: [RollingModalityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingModalityCycleEngine(_ flags: Kit.Flags.Registry) -> RollingModalityCycleEngine {
        return RollingModalityCycleEngine(
            steps: [
                TieredRollingModalityCycleAdjuster(
                    bounds: [4825.0, 5756.0, 6625.0, 7794.0],
                    rates: [1.03, 1.13, 0.89, 0.9]
                ),
                RoundingRollingModalityCycleAdjuster(step: 0.5),
                FlaggedRollingModalityCycleAdjuster(
                    flags: flags,
                    flag: "rolling-modality-cycle-primary",
                    percent: 5.6
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 64540.2
        )
    }
}
