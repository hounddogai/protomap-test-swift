import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census plan calculation.
    protocol CensusPlanStep {
        func describe() -> String
        func adjust(_ item: CensusPlan, value: Double) -> Double
    }

    final class MinimumCensusPlanAdjuster: CensusPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CensusPlanDurationMinutesOffsetAdjuster: CensusPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentCensusPlanAdjuster: CensusPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCensusPlanAdjuster: CensusPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCensusPlanAdjuster: CensusPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCensusPlanAdjuster: CensusPlanStep {
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

        func adjust(_ item: CensusPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census plan steps in order and keeps a trace of each.
    final class CensusPlanEngine {
        var steps: [any CensusPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusPlan) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CensusPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusPlanEngine(_ flags: Kit.Flags.Registry) -> CensusPlanEngine {
        return CensusPlanEngine(
            steps: [
                MinimumCensusPlanAdjuster(minimum: 11.0),
                CensusPlanDurationMinutesOffsetAdjuster(weight: 0.1),
                PercentCensusPlanAdjuster(percent: -0.3),
                TitleCensusPlanAdjuster(factors: ["west": 0.78]),
                RoundingCensusPlanAdjuster(step: 0.1),
                FlaggedCensusPlanAdjuster(flags: flags, flag: "census-plan-tiered", percent: -9.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 57590.4
        )
    }
}
