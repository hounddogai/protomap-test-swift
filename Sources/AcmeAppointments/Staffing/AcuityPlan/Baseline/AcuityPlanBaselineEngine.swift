import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan baseline calculation.
    protocol AcuityPlanBaselineStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double
    }

    final class CountryAcuityPlanBaselineAdjuster: AcuityPlanBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAcuityPlanBaselineAdjuster: AcuityPlanBaselineStep {
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

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAcuityPlanBaselineAdjuster: AcuityPlanBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAcuityPlanBaselineAdjuster: AcuityPlanBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAcuityPlanBaselineAdjuster: AcuityPlanBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AcuityPlanBaselineCapacityOffsetAdjuster: AcuityPlanBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: AcuityPlanBaseline, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the acuity plan baseline steps in order and keeps a trace of each.
    final class AcuityPlanBaselineEngine {
        var steps: [any AcuityPlanBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanBaseline) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [AcuityPlanBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanBaselineEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanBaselineEngine {
        return AcuityPlanBaselineEngine(
            steps: [
                CountryAcuityPlanBaselineAdjuster(factors: ["online": 0.84, "west": 1.18]),
                FlaggedAcuityPlanBaselineAdjuster(flags: flags, flag: "acuity-plan-baseline-adaptive", percent: -0.7),
                MinimumAcuityPlanBaselineAdjuster(minimum: 37.2),
                CapAcuityPlanBaselineAdjuster(cap: 22147.0),
                RoundingAcuityPlanBaselineAdjuster(step: 0.25),
                AcuityPlanBaselineCapacityOffsetAdjuster(weight: 1.85),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 77335.0
        )
    }
}
