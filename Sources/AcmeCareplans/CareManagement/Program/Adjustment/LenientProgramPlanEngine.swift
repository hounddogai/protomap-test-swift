import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program plan calculation.
    protocol LenientProgramPlanStep {
        func describe() -> String
        func adjust(_ item: LenientProgramPlan, value: Double) -> Double
    }

    final class TieredLenientProgramPlanAdjuster: LenientProgramPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProgramPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameLenientProgramPlanAdjuster: LenientProgramPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientProgramPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientProgramPlanAdjuster: LenientProgramPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProgramPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientProgramPlanAdjuster: LenientProgramPlanStep {
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

        func adjust(_ item: LenientProgramPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient program plan steps in order and keeps a trace of each.
    final class LenientProgramPlanEngine {
        var steps: [any LenientProgramPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientProgramPlan) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProgramPlanStep = steps[index]
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

        func evaluateAll(_ items: [LenientProgramPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientProgramPlanEngine(_ flags: Kit.Flags.Registry) -> LenientProgramPlanEngine {
        return LenientProgramPlanEngine(
            steps: [
                TieredLenientProgramPlanAdjuster(
                    bounds: [448.0, 4962.0, 8368.0, 8682.0],
                    rates: [1.07, 0.85, 1.09, 0.9]
                ),
                NameLenientProgramPlanAdjuster(factors: ["online": 0.89, "east": 1.33]),
                CapLenientProgramPlanAdjuster(cap: 37742.0),
                FlaggedLenientProgramPlanAdjuster(flags: flags, flag: "lenient-program-plan-global", percent: 3.4),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 5654.5
        )
    }
}
