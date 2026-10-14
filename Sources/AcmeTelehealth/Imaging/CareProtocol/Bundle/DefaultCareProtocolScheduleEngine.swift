import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default care protocol schedule calculation.
    protocol DefaultCareProtocolScheduleStep {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolSchedule, value: Double) -> Double
    }

    final class PercentDefaultCareProtocolScheduleAdjuster: DefaultCareProtocolScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCareProtocolSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultCareProtocolScheduleAdjuster: DefaultCareProtocolScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultCareProtocolScheduleAdjuster: DefaultCareProtocolScheduleStep {
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

        func adjust(_ item: DefaultCareProtocolSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default care protocol schedule steps in order and keeps a trace of each.
    final class DefaultCareProtocolScheduleEngine {
        var steps: [any DefaultCareProtocolScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCareProtocolSchedule) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCareProtocolScheduleStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCareProtocolSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolScheduleEngine(_ flags: Kit.Flags.Registry) -> DefaultCareProtocolScheduleEngine {
        return DefaultCareProtocolScheduleEngine(
            steps: [
                PercentDefaultCareProtocolScheduleAdjuster(percent: -3.6),
                TieredDefaultCareProtocolScheduleAdjuster(bounds: [464.0, 7113.0, 9616.0], rates: [0.82, 0.82, 1.03]),
                FlaggedDefaultCareProtocolScheduleAdjuster(
                    flags: flags,
                    flag: "default-care-protocol-schedule-legacy",
                    percent: -9.3
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 27862.6
        )
    }
}
