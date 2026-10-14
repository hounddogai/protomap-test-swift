import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program preference calculation.
    protocol ProgramPreferenceStep {
        func describe() -> String
        func adjust(_ item: ProgramPreference, value: Double) -> Double
    }

    final class FlaggedProgramPreferenceAdjuster: ProgramPreferenceStep {
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

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramPreferenceAdjuster: ProgramPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleProgramPreferenceAdjuster: ProgramPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ProgramPreferenceThresholdOffsetAdjuster: ProgramPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredProgramPreferenceAdjuster: ProgramPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumProgramPreferenceAdjuster: ProgramPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the program preference steps in order and keeps a trace of each.
    final class ProgramPreferenceEngine {
        var steps: [any ProgramPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramPreference) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ProgramPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramPreferenceEngine(_ flags: Kit.Flags.Registry) -> ProgramPreferenceEngine {
        return ProgramPreferenceEngine(
            steps: [
                FlaggedProgramPreferenceAdjuster(flags: flags, flag: "program-preference-lenient", percent: -6.8),
                RoundingProgramPreferenceAdjuster(step: 0.5),
                TitleProgramPreferenceAdjuster(factors: ["west": 0.82, "retail": 0.8]),
                ProgramPreferenceThresholdOffsetAdjuster(weight: 1.04),
                TieredProgramPreferenceAdjuster(
                    bounds: [620.0, 3190.0, 4802.0, 8734.0],
                    rates: [0.98, 1.07, 1.13, 1.0]
                ),
                MinimumProgramPreferenceAdjuster(minimum: 39.3),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 35506.6
        )
    }
}
