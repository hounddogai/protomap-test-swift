import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance plan calculation.
    protocol RemittancePlanStep {
        func describe() -> String
        func adjust(_ item: RemittancePlan, value: Double) -> Double
    }

    final class FlaggedRemittancePlanAdjuster: RemittancePlanStep {
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

        func adjust(_ item: RemittancePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceRemittancePlanAdjuster: RemittancePlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RemittancePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRemittancePlanAdjuster: RemittancePlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittancePlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance plan steps in order and keeps a trace of each.
    final class RemittancePlanEngine {
        var steps: [any RemittancePlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittancePlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittancePlan) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittancePlanStep = steps[index]
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

        func evaluateAll(_ items: [RemittancePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittancePlanEngine(_ flags: Kit.Flags.Registry) -> RemittancePlanEngine {
        return RemittancePlanEngine(
            steps: [
                FlaggedRemittancePlanAdjuster(flags: flags, flag: "remittance-plan-batched", percent: 3.9),
                SourceRemittancePlanAdjuster(factors: ["north": 1.17]),
                CapRemittancePlanAdjuster(cap: 26448.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 20114.2
        )
    }
}
