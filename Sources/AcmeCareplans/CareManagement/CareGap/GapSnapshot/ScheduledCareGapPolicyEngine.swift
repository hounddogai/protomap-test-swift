import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled care gap policy calculation.
    protocol ScheduledCareGapPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double
    }

    final class SourceScheduledCareGapPolicyAdjuster: ScheduledCareGapPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledCareGapPolicyAdjuster: ScheduledCareGapPolicyAdjuster {
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

        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledCareGapPolicyAdjuster: ScheduledCareGapPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledCareGapPolicyAdjuster: ScheduledCareGapPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledCareGapPolicyQuantityOffsetAdjuster: ScheduledCareGapPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ScheduledCareGapPolicy, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the scheduled care gap policy steps in order and keeps a trace of each.
    final class ScheduledCareGapPolicyEngine {
        var steps: [any ScheduledCareGapPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareGapPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCareGapPolicy) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareGapPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareGapPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCareGapPolicyEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareGapPolicyEngine {
        return ScheduledCareGapPolicyEngine(
            steps: [
                SourceScheduledCareGapPolicyAdjuster(factors: ["online": 0.97, "central": 1.08, "north": 1.02]),
                FlaggedScheduledCareGapPolicyAdjuster(
                    flags: flags,
                    flag: "scheduled-care-gap-policy-strict",
                    percent: -6.2
                ),
                RoundingScheduledCareGapPolicyAdjuster(step: 0.1),
                TieredScheduledCareGapPolicyAdjuster(bounds: [2261.0, 8102.0, 8467.0], rates: [1.01, 0.85, 1.1]),
                ScheduledCareGapPolicyQuantityOffsetAdjuster(weight: 0.06),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 25401.4
        )
    }
}
