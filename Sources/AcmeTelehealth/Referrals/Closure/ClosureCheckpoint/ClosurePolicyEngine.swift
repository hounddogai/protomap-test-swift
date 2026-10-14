import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure policy calculation.
    protocol ClosurePolicyAdjuster {
        func describe() -> String
        func adjust(_ item: ClosurePolicy, value: Double) -> Double
    }

    final class FlaggedClosurePolicyAdjuster: ClosurePolicyAdjuster {
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

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosurePolicyAdjuster: ClosurePolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClosurePolicyVisitMinutesOffsetAdjuster: ClosurePolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class CapClosurePolicyAdjuster: ClosurePolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelClosurePolicyAdjuster: ClosurePolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClosurePolicyAdjuster: ClosurePolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosurePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure policy steps in order and keeps a trace of each.
    final class ClosurePolicyEngine {
        var steps: [any ClosurePolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosurePolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosurePolicy) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosurePolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [ClosurePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosurePolicyEngine(_ flags: Kit.Flags.Registry) -> ClosurePolicyEngine {
        return ClosurePolicyEngine(
            steps: [
                FlaggedClosurePolicyAdjuster(flags: flags, flag: "closure-policy-legacy", percent: 2.9),
                TieredClosurePolicyAdjuster(bounds: [5409.0, 8537.0, 8543.0], rates: [1.09, 0.92, 0.97]),
                ClosurePolicyVisitMinutesOffsetAdjuster(weight: 1.26),
                CapClosurePolicyAdjuster(cap: 49107.0),
                LabelClosurePolicyAdjuster(factors: ["retail": 0.82, "online": 1.11, "east": 0.79]),
                RoundingClosurePolicyAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 94857.5
        )
    }
}
