import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled read plan calculation.
    protocol ScheduledReadPlanStep {
        func describe() -> String
        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double
    }

    final class CapScheduledReadPlanAdjuster: ScheduledReadPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledReadPlanQuantityOffsetAdjuster: ScheduledReadPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TitleScheduledReadPlanAdjuster: ScheduledReadPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledReadPlanAdjuster: ScheduledReadPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledReadPlanAdjuster: ScheduledReadPlanStep {
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

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledReadPlanAdjuster: ScheduledReadPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledReadPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled read plan steps in order and keeps a trace of each.
    final class ScheduledReadPlanEngine {
        var steps: [any ScheduledReadPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledReadPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledReadPlan) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledReadPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledReadPlanEngine(_ flags: Kit.Flags.Registry) -> ScheduledReadPlanEngine {
        return ScheduledReadPlanEngine(
            steps: [
                CapScheduledReadPlanAdjuster(cap: 19555.0),
                ScheduledReadPlanQuantityOffsetAdjuster(weight: 1.98),
                TitleScheduledReadPlanAdjuster(factors: ["west": 1.3]),
                PercentScheduledReadPlanAdjuster(percent: 1.1),
                FlaggedScheduledReadPlanAdjuster(flags: flags, flag: "scheduled-read-plan-regional", percent: -8.6),
                RoundingScheduledReadPlanAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 32310.2
        )
    }
}
