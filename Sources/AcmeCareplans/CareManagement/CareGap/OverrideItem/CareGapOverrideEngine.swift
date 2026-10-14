import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap override calculation.
    protocol CareGapOverrideStep {
        func describe() -> String
        func adjust(_ item: CareGapOverride, value: Double) -> Double
    }

    final class CapCareGapOverrideAdjuster: CareGapOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCareGapOverrideAdjuster: CareGapOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareGapOverrideAdjuster: CareGapOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCareGapOverrideAdjuster: CareGapOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareGapOverrideRevisionOffsetAdjuster: CareGapOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedCareGapOverrideAdjuster: CareGapOverrideStep {
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

        func adjust(_ item: CareGapOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap override steps in order and keeps a trace of each.
    final class CareGapOverrideEngine {
        var steps: [any CareGapOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareGapOverride) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CareGapOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareGapOverrideEngine(_ flags: Kit.Flags.Registry) -> CareGapOverrideEngine {
        return CareGapOverrideEngine(
            steps: [
                CapCareGapOverrideAdjuster(cap: 5604.0),
                RoundingCareGapOverrideAdjuster(step: 1.0),
                PercentCareGapOverrideAdjuster(percent: 19.2),
                TitleCareGapOverrideAdjuster(factors: ["retail": 0.75, "east": 0.92, "north": 1.09]),
                CareGapOverrideRevisionOffsetAdjuster(weight: 0.73),
                FlaggedCareGapOverrideAdjuster(flags: flags, flag: "care-gap-override-lenient", percent: 3.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 20833.7
        )
    }
}
