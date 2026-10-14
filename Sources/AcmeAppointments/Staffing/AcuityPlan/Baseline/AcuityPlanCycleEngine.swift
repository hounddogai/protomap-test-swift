import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan cycle calculation.
    protocol AcuityPlanCycleAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double
    }

    final class PercentAcuityPlanCycleAdjuster: AcuityPlanCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AcuityPlanCycleScoreOffsetAdjuster: AcuityPlanCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingAcuityPlanCycleAdjuster: AcuityPlanCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitAcuityPlanCycleAdjuster: AcuityPlanCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAcuityPlanCycleAdjuster: AcuityPlanCycleAdjuster {
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

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAcuityPlanCycleAdjuster: AcuityPlanCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan cycle steps in order and keeps a trace of each.
    final class AcuityPlanCycleEngine {
        var steps: [any AcuityPlanCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanCycle) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanCycleEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanCycleEngine {
        return AcuityPlanCycleEngine(
            steps: [
                PercentAcuityPlanCycleAdjuster(percent: 9.4),
                AcuityPlanCycleScoreOffsetAdjuster(weight: 1.84),
                RoundingAcuityPlanCycleAdjuster(step: 5.0),
                UnitAcuityPlanCycleAdjuster(factors: ["central": 1.01, "west": 0.84]),
                FlaggedAcuityPlanCycleAdjuster(flags: flags, flag: "acuity-plan-cycle-manual", percent: -0.5),
                MinimumAcuityPlanCycleAdjuster(minimum: 36.5),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 52765.9
        )
    }
}
