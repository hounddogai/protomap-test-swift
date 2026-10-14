import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall milestone calculation.
    protocol DefaultRecallMilestoneStep {
        func describe() -> String
        func adjust(_ item: DefaultRecallMilestone, value: Double) -> Double
    }

    final class FlaggedDefaultRecallMilestoneAdjuster: DefaultRecallMilestoneStep {
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

        func adjust(_ item: DefaultRecallMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultRecallMilestoneAdjuster: DefaultRecallMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRecallMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultRecallMilestoneAdjuster: DefaultRecallMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRecallMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultRecallMilestoneAdjuster: DefaultRecallMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRecallMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default recall milestone steps in order and keeps a trace of each.
    final class DefaultRecallMilestoneEngine {
        var steps: [any DefaultRecallMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultRecallMilestone) -> Double {
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

        func evaluateAll(_ items: [DefaultRecallMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallMilestoneEngine(_ flags: Kit.Flags.Registry) -> DefaultRecallMilestoneEngine {
        return DefaultRecallMilestoneEngine(
            steps: [
                FlaggedDefaultRecallMilestoneAdjuster(
                    flags: flags,
                    flag: "default-recall-milestone-scheduled",
                    percent: 1.4
                ),
                PercentDefaultRecallMilestoneAdjuster(percent: -11.9),
                TieredDefaultRecallMilestoneAdjuster(
                    bounds: [1007.0, 2496.0, 8672.0, 9722.0],
                    rates: [1.0, 1.15, 1.12, 0.91]
                ),
                MinimumDefaultRecallMilestoneAdjuster(minimum: 30.1),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 43222.1
        )
    }
}
