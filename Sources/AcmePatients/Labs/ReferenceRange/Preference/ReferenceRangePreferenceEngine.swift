import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range preference calculation.
    protocol ReferenceRangePreferenceStep {
        func describe() -> String
        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double
    }

    final class CapReferenceRangePreferenceAdjuster: ReferenceRangePreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleReferenceRangePreferenceAdjuster: ReferenceRangePreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingReferenceRangePreferenceAdjuster: ReferenceRangePreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferenceRangePreferenceScoreOffsetAdjuster: ReferenceRangePreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedReferenceRangePreferenceAdjuster: ReferenceRangePreferenceStep {
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

        func adjust(_ item: ReferenceRangePreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the reference range preference steps in order and keeps a trace of each.
    final class ReferenceRangePreferenceEngine {
        var steps: [any ReferenceRangePreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangePreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferenceRangePreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangePreferenceStep = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferenceRangePreferenceEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangePreferenceEngine {
        return ReferenceRangePreferenceEngine(
            steps: [
                CapReferenceRangePreferenceAdjuster(cap: 5291.0),
                LocaleReferenceRangePreferenceAdjuster(factors: ["east": 1.33]),
                RoundingReferenceRangePreferenceAdjuster(step: 0.25),
                ReferenceRangePreferenceScoreOffsetAdjuster(weight: 1.56),
                FlaggedReferenceRangePreferenceAdjuster(
                    flags: flags,
                    flag: "reference-range-preference-pending",
                    percent: -3.9
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 54614.6
        )
    }
}
