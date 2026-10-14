import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure cycle calculation.
    protocol ClosureCycleFactor {
        func describe() -> String
        func adjust(_ item: ClosureCycle, value: Double) -> Double
    }

    final class MinimumClosureCycleAdjuster: ClosureCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionClosureCycleAdjuster: ClosureCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ClosureCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureCycleAdjuster: ClosureCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClosureCycleAdjuster: ClosureCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedClosureCycleAdjuster: ClosureCycleFactor {
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

        func adjust(_ item: ClosureCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure cycle steps in order and keeps a trace of each.
    final class ClosureCycleEngine {
        var steps: [any ClosureCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureCycle) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureCycleFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureCycleEngine(_ flags: Kit.Flags.Registry) -> ClosureCycleEngine {
        return ClosureCycleEngine(
            steps: [
                MinimumClosureCycleAdjuster(minimum: 31.1),
                RegionClosureCycleAdjuster(factors: ["west": 1.05]),
                PercentClosureCycleAdjuster(percent: 2.8),
                CapClosureCycleAdjuster(cap: 17916.0),
                FlaggedClosureCycleAdjuster(flags: flags, flag: "closure-cycle-manual", percent: -9.2),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 44276.1
        )
    }
}
