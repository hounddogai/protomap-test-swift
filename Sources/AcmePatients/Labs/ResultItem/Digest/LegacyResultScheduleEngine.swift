import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy result schedule calculation.
    protocol LegacyResultScheduleFactor {
        func describe() -> String
        func adjust(_ item: LegacyResultSchedule, value: Double) -> Double
    }

    final class FlaggedLegacyResultScheduleAdjuster: LegacyResultScheduleFactor {
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

        func adjust(_ item: LegacyResultSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyResultScheduleAdjuster: LegacyResultScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyResultSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLegacyResultScheduleAdjuster: LegacyResultScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyResultSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyResultScheduleAdjuster: LegacyResultScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyResultSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy result schedule steps in order and keeps a trace of each.
    final class LegacyResultScheduleEngine {
        var steps: [any LegacyResultScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyResultScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyResultSchedule) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LegacyResultSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyResultScheduleEngine(_ flags: Kit.Flags.Registry) -> LegacyResultScheduleEngine {
        return LegacyResultScheduleEngine(
            steps: [
                FlaggedLegacyResultScheduleAdjuster(
                    flags: flags,
                    flag: "legacy-result-schedule-pending",
                    percent: -1.1
                ),
                TieredLegacyResultScheduleAdjuster(bounds: [368.0, 3671.0, 6326.0], rates: [1.14, 0.91, 0.96]),
                TitleLegacyResultScheduleAdjuster(factors: ["south": 1.4, "online": 1.21, "east": 1.07]),
                MinimumLegacyResultScheduleAdjuster(minimum: 19.7),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 96963.8
        )
    }
}
