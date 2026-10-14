import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary isolation schedule calculation.
    protocol PrimaryIsolationScheduleFactor {
        func describe() -> String
        func adjust(_ item: PrimaryIsolationSchedule, value: Double) -> Double
    }

    final class TieredPrimaryIsolationScheduleAdjuster: PrimaryIsolationScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryIsolationSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPrimaryIsolationScheduleAdjuster: PrimaryIsolationScheduleFactor {
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

        func adjust(_ item: PrimaryIsolationSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryIsolationScheduleAdjuster: PrimaryIsolationScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryIsolationSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary isolation schedule steps in order and keeps a trace of each.
    final class PrimaryIsolationScheduleEngine {
        var steps: [any PrimaryIsolationScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryIsolationScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryIsolationSchedule) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [PrimaryIsolationSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryIsolationScheduleEngine(_ flags: Kit.Flags.Registry) -> PrimaryIsolationScheduleEngine {
        return PrimaryIsolationScheduleEngine(
            steps: [
                TieredPrimaryIsolationScheduleAdjuster(
                    bounds: [3099.0, 4439.0, 6004.0, 8891.0],
                    rates: [1.16, 0.89, 1.1, 1.17]
                ),
                FlaggedPrimaryIsolationScheduleAdjuster(
                    flags: flags,
                    flag: "primary-isolation-schedule-manual",
                    percent: -9.8
                ),
                MinimumPrimaryIsolationScheduleAdjuster(minimum: 25.9),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 77405.8
        )
    }
}
