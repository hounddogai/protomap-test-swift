import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network schedule calculation.
    protocol ManualNetworkScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double
    }

    final class RoundingManualNetworkScheduleAdjuster: ManualNetworkScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualNetworkScheduleAdjuster: ManualNetworkScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualNetworkScheduleAdjuster: ManualNetworkScheduleAdjuster {
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

        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualNetworkScheduleAdjuster: ManualNetworkScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualNetworkScheduleAdjuster: ManualNetworkScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual network schedule steps in order and keeps a trace of each.
    final class ManualNetworkScheduleEngine {
        var steps: [any ManualNetworkScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualNetworkSchedule) -> Double {
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

        func evaluateAll(_ items: [ManualNetworkSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualNetworkScheduleEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkScheduleEngine {
        return ManualNetworkScheduleEngine(
            steps: [
                RoundingManualNetworkScheduleAdjuster(step: 0.5),
                CapManualNetworkScheduleAdjuster(cap: 41801.0),
                FlaggedManualNetworkScheduleAdjuster(
                    flags: flags,
                    flag: "manual-network-schedule-primary",
                    percent: 0.8
                ),
                MinimumManualNetworkScheduleAdjuster(minimum: 36.9),
                TieredManualNetworkScheduleAdjuster(
                    bounds: [1350.0, 1740.0, 1855.0, 5174.0],
                    rates: [0.9, 0.99, 1.08, 1.08]
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 27267.7
        )
    }
}
