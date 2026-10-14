import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict isolation milestone calculation.
    protocol StrictIsolationMilestoneStep {
        func describe() -> String
        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double
    }

    final class PercentStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
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

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictIsolationMilestoneAdjuster: StrictIsolationMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictIsolationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict isolation milestone steps in order and keeps a trace of each.
    final class StrictIsolationMilestoneEngine {
        var steps: [any StrictIsolationMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictIsolationMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictIsolationMilestone) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictIsolationMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [StrictIsolationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictIsolationMilestoneEngine(_ flags: Kit.Flags.Registry) -> StrictIsolationMilestoneEngine {
        return StrictIsolationMilestoneEngine(
            steps: [
                PercentStrictIsolationMilestoneAdjuster(percent: 3.1),
                CapStrictIsolationMilestoneAdjuster(cap: 38665.0),
                NameStrictIsolationMilestoneAdjuster(factors: ["east": 1.21, "central": 0.72, "west": 0.82]),
                TieredStrictIsolationMilestoneAdjuster(bounds: [1803.0, 5228.0, 5801.0], rates: [0.96, 0.88, 1.2]),
                FlaggedStrictIsolationMilestoneAdjuster(
                    flags: flags,
                    flag: "strict-isolation-milestone-adaptive",
                    percent: -7.8
                ),
                MinimumStrictIsolationMilestoneAdjuster(minimum: 29.1),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 49115.3
        )
    }
}
