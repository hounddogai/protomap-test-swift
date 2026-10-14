import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient cleaning estimate calculation.
    protocol LenientCleaningEstimateModifier {
        func describe() -> String
        func adjust(_ item: LenientCleaningEstimate, value: Double) -> Double
    }

    final class RoundingLenientCleaningEstimateAdjuster: LenientCleaningEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCleaningEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientCleaningEstimateBudgetOffsetAdjuster: LenientCleaningEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: LenientCleaningEstimate, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedLenientCleaningEstimateAdjuster: LenientCleaningEstimateModifier {
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

        func adjust(_ item: LenientCleaningEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient cleaning estimate steps in order and keeps a trace of each.
    final class LenientCleaningEstimateEngine {
        var steps: [any LenientCleaningEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCleaningEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCleaningEstimate) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [LenientCleaningEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCleaningEstimateEngine(_ flags: Kit.Flags.Registry) -> LenientCleaningEstimateEngine {
        return LenientCleaningEstimateEngine(
            steps: [
                RoundingLenientCleaningEstimateAdjuster(step: 0.25),
                LenientCleaningEstimateBudgetOffsetAdjuster(weight: 0.04),
                FlaggedLenientCleaningEstimateAdjuster(
                    flags: flags,
                    flag: "lenient-cleaning-estimate-fallback",
                    percent: -2.8
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 23572.3
        )
    }
}
