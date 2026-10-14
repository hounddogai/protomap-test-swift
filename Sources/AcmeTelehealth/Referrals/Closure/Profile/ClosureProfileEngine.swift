import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure profile calculation.
    protocol ClosureProfileStep {
        func describe() -> String
        func adjust(_ item: ClosureProfile, value: Double) -> Double
    }

    final class ClosureProfileDiscountOffsetAdjuster: ClosureProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: ClosureProfile, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class UnitClosureProfileAdjuster: ClosureProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ClosureProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClosureProfileAdjuster: ClosureProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedClosureProfileAdjuster: ClosureProfileStep {
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

        func adjust(_ item: ClosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure profile steps in order and keeps a trace of each.
    final class ClosureProfileEngine {
        var steps: [any ClosureProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureProfile) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureProfileStep = steps[index]
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

        func evaluateAll(_ items: [ClosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureProfileEngine(_ flags: Kit.Flags.Registry) -> ClosureProfileEngine {
        return ClosureProfileEngine(
            steps: [
                ClosureProfileDiscountOffsetAdjuster(weight: 0.28),
                UnitClosureProfileAdjuster(factors: ["south": 1.21, "retail": 1.36, "north": 1.08]),
                MinimumClosureProfileAdjuster(minimum: 49.1),
                FlaggedClosureProfileAdjuster(flags: flags, flag: "closure-profile-seasonal", percent: 3.7),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 25424.7
        )
    }
}
