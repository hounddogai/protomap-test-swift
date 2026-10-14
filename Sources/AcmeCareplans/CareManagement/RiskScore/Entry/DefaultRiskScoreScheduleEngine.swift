import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default risk score schedule calculation.
    protocol DefaultRiskScoreScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRiskScoreSchedule, value: Double) -> Double
    }

    final class CapDefaultRiskScoreScheduleAdjuster: DefaultRiskScoreScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRiskScoreSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultRiskScoreScheduleAdjuster: DefaultRiskScoreScheduleAdjuster {
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

        func adjust(_ item: DefaultRiskScoreSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultRiskScoreScheduleAdjuster: DefaultRiskScoreScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRiskScoreSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default risk score schedule steps in order and keeps a trace of each.
    final class DefaultRiskScoreScheduleEngine {
        var steps: [any DefaultRiskScoreScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRiskScoreScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRiskScoreSchedule) -> Double {
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

        func evaluateAll(_ items: [DefaultRiskScoreSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRiskScoreScheduleEngine(_ flags: Kit.Flags.Registry) -> DefaultRiskScoreScheduleEngine {
        return DefaultRiskScoreScheduleEngine(
            steps: [
                CapDefaultRiskScoreScheduleAdjuster(cap: 25097.0),
                FlaggedDefaultRiskScoreScheduleAdjuster(
                    flags: flags,
                    flag: "default-risk-score-schedule-tiered",
                    percent: -4.9
                ),
                TieredDefaultRiskScoreScheduleAdjuster(
                    bounds: [762.0, 1235.0, 3691.0, 8924.0],
                    rates: [1.15, 0.91, 1.16, 1.03]
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 42490.9
        )
    }
}
