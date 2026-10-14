import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled witness milestone calculation.
    protocol ScheduledWitnessMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double
    }

    final class UnitScheduledWitnessMilestoneAdjuster: ScheduledWitnessMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledWitnessMilestoneAdjuster: ScheduledWitnessMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledWitnessMilestoneAdjuster: ScheduledWitnessMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledWitnessMilestoneAdjuster: ScheduledWitnessMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedScheduledWitnessMilestoneAdjuster: ScheduledWitnessMilestoneAdjuster {
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

        func adjust(_ item: ScheduledWitnessMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled witness milestone steps in order and keeps a trace of each.
    final class ScheduledWitnessMilestoneEngine {
        var steps: [any ScheduledWitnessMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledWitnessMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledWitnessMilestone) -> Double {
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

        func evaluateAll(_ items: [ScheduledWitnessMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledWitnessMilestoneEngine(_ flags: Kit.Flags.Registry) -> ScheduledWitnessMilestoneEngine {
        return ScheduledWitnessMilestoneEngine(
            steps: [
                UnitScheduledWitnessMilestoneAdjuster(factors: ["online": 1.24, "south": 1.19, "retail": 1.0]),
                MinimumScheduledWitnessMilestoneAdjuster(minimum: 27.9),
                CapScheduledWitnessMilestoneAdjuster(cap: 47518.0),
                TieredScheduledWitnessMilestoneAdjuster(bounds: [3294.0, 5319.0], rates: [1.18, 0.8]),
                FlaggedScheduledWitnessMilestoneAdjuster(
                    flags: flags,
                    flag: "scheduled-witness-milestone-default",
                    percent: 6.4
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 5075.4
        )
    }
}
