import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan baseline calculation.
    protocol LenientAcuityPlanBaselineFactor {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanBaseline, value: Double) -> Double
    }

    final class MinimumLenientAcuityPlanBaselineAdjuster: LenientAcuityPlanBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAcuityPlanBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientAcuityPlanBaselineAdjuster: LenientAcuityPlanBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAcuityPlanBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientAcuityPlanBaselineAdjuster: LenientAcuityPlanBaselineFactor {
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

        func adjust(_ item: LenientAcuityPlanBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient acuity plan baseline steps in order and keeps a trace of each.
    final class LenientAcuityPlanBaselineEngine {
        var steps: [any LenientAcuityPlanBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientAcuityPlanBaseline) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LenientAcuityPlanBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanBaselineEngine(_ flags: Kit.Flags.Registry) -> LenientAcuityPlanBaselineEngine {
        return LenientAcuityPlanBaselineEngine(
            steps: [
                MinimumLenientAcuityPlanBaselineAdjuster(minimum: 31.1),
                RoundingLenientAcuityPlanBaselineAdjuster(step: 0.5),
                FlaggedLenientAcuityPlanBaselineAdjuster(
                    flags: flags,
                    flag: "lenient-acuity-plan-baseline-regional",
                    percent: -9.0
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 30366.9
        )
    }
}
