import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial milestone calculation.
    protocol DenialMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: DenialMilestone, value: Double) -> Double
    }

    final class FlaggedDenialMilestoneAdjuster: DenialMilestoneAdjuster {
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

        func adjust(_ item: DenialMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDenialMilestoneAdjuster: DenialMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDenialMilestoneAdjuster: DenialMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDenialMilestoneAdjuster: DenialMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the denial milestone steps in order and keeps a trace of each.
    final class DenialMilestoneEngine {
        var steps: [any DenialMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialMilestone) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialMilestoneEngine(_ flags: Kit.Flags.Registry) -> DenialMilestoneEngine {
        return DenialMilestoneEngine(
            steps: [
                FlaggedDenialMilestoneAdjuster(flags: flags, flag: "denial-milestone-weighted", percent: 8.1),
                TieredDenialMilestoneAdjuster(bounds: [7561.0, 8365.0], rates: [0.82, 1.06]),
                CapDenialMilestoneAdjuster(cap: 15060.0),
                RoundingDenialMilestoneAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 30976.3
        )
    }
}
