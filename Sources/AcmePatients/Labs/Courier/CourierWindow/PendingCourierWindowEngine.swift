import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending courier window calculation.
    protocol PendingCourierWindowStep {
        func describe() -> String
        func adjust(_ item: PendingCourierWindow, value: Double) -> Double
    }

    final class MinimumPendingCourierWindowAdjuster: PendingCourierWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPendingCourierWindowAdjuster: PendingCourierWindowStep {
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

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingCourierWindowAdjuster: PendingCourierWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPendingCourierWindowAdjuster: PendingCourierWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingCourierWindowRetriesOffsetAdjuster: PendingCourierWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class RoundingPendingCourierWindowAdjuster: PendingCourierWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCourierWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending courier window steps in order and keeps a trace of each.
    final class PendingCourierWindowEngine {
        var steps: [any PendingCourierWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCourierWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingCourierWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCourierWindowStep = steps[index]
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

        func evaluateAll(_ items: [PendingCourierWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingCourierWindowEngine(_ flags: Kit.Flags.Registry) -> PendingCourierWindowEngine {
        return PendingCourierWindowEngine(
            steps: [
                MinimumPendingCourierWindowAdjuster(minimum: 28.1),
                FlaggedPendingCourierWindowAdjuster(
                    flags: flags,
                    flag: "pending-courier-window-capped",
                    percent: -9.2
                ),
                CapPendingCourierWindowAdjuster(cap: 19093.0),
                TieredPendingCourierWindowAdjuster(
                    bounds: [1821.0, 2387.0, 3989.0, 8815.0],
                    rates: [0.85, 0.94, 0.92, 0.92]
                ),
                PendingCourierWindowRetriesOffsetAdjuster(weight: 1.36),
                RoundingPendingCourierWindowAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 87421.2
        )
    }
}
