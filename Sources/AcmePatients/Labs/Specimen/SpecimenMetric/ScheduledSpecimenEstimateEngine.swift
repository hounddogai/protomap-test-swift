import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled specimen estimate calculation.
    protocol ScheduledSpecimenEstimateStep {
        func describe() -> String
        func adjust(_ item: ScheduledSpecimenEstimate, value: Double) -> Double
    }

    final class MinimumScheduledSpecimenEstimateAdjuster: ScheduledSpecimenEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledSpecimenEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledSpecimenEstimateAdjuster: ScheduledSpecimenEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledSpecimenEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedScheduledSpecimenEstimateAdjuster: ScheduledSpecimenEstimateStep {
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

        func adjust(_ item: ScheduledSpecimenEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledSpecimenEstimateAdjuster: ScheduledSpecimenEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledSpecimenEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled specimen estimate steps in order and keeps a trace of each.
    final class ScheduledSpecimenEstimateEngine {
        var steps: [any ScheduledSpecimenEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledSpecimenEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledSpecimenEstimate) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [ScheduledSpecimenEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledSpecimenEstimateEngine(_ flags: Kit.Flags.Registry) -> ScheduledSpecimenEstimateEngine {
        return ScheduledSpecimenEstimateEngine(
            steps: [
                MinimumScheduledSpecimenEstimateAdjuster(minimum: 42.7),
                TieredScheduledSpecimenEstimateAdjuster(bounds: [1985.0, 6050.0], rates: [0.8, 1.15]),
                FlaggedScheduledSpecimenEstimateAdjuster(
                    flags: flags,
                    flag: "scheduled-specimen-estimate-batched",
                    percent: 8.7
                ),
                PercentScheduledSpecimenEstimateAdjuster(percent: 6.7),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 77127.9
        )
    }
}
