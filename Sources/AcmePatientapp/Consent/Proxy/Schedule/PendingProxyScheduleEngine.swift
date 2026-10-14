import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending proxy schedule calculation.
    protocol PendingProxyScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: PendingProxySchedule, value: Double) -> Double
    }

    final class MinimumPendingProxyScheduleAdjuster: PendingProxyScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingProxySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingProxyScheduleAdjuster: PendingProxyScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingProxySchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingProxyScheduleAdjuster: PendingProxyScheduleAdjuster {
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

        func adjust(_ item: PendingProxySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending proxy schedule steps in order and keeps a trace of each.
    final class PendingProxyScheduleEngine {
        var steps: [any PendingProxyScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingProxyScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingProxySchedule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingProxyScheduleAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingProxySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingProxyScheduleEngine(_ flags: Kit.Flags.Registry) -> PendingProxyScheduleEngine {
        return PendingProxyScheduleEngine(
            steps: [
                MinimumPendingProxyScheduleAdjuster(minimum: 42.1),
                TieredPendingProxyScheduleAdjuster(
                    bounds: [997.0, 6107.0, 6142.0, 8399.0],
                    rates: [0.96, 0.8, 1.16, 0.96]
                ),
                FlaggedPendingProxyScheduleAdjuster(
                    flags: flags,
                    flag: "pending-proxy-schedule-fallback",
                    percent: 8.4
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 32071.3
        )
    }
}
