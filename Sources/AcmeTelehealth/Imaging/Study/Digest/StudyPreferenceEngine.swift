import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study preference calculation.
    protocol StudyPreferenceModifier {
        func describe() -> String
        func adjust(_ item: StudyPreference, value: Double) -> Double
    }

    final class NameStudyPreferenceAdjuster: StudyPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStudyPreferenceAdjuster: StudyPreferenceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStudyPreferenceAdjuster: StudyPreferenceModifier {
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

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStudyPreferenceAdjuster: StudyPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStudyPreferenceAdjuster: StudyPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStudyPreferenceAdjuster: StudyPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study preference steps in order and keeps a trace of each.
    final class StudyPreferenceEngine {
        var steps: [any StudyPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StudyPreference) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [StudyPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStudyPreferenceEngine(_ flags: Kit.Flags.Registry) -> StudyPreferenceEngine {
        return StudyPreferenceEngine(
            steps: [
                NameStudyPreferenceAdjuster(factors: ["south": 0.96, "retail": 0.85]),
                CapStudyPreferenceAdjuster(cap: 20047.0),
                FlaggedStudyPreferenceAdjuster(flags: flags, flag: "study-preference-fallback", percent: -5.4),
                RoundingStudyPreferenceAdjuster(step: 0.05),
                TieredStudyPreferenceAdjuster(bounds: [396.0, 4936.0, 5336.0, 8244.0], rates: [1.16, 1.06, 0.96, 0.9]),
                PercentStudyPreferenceAdjuster(percent: -9.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 77375.5
        )
    }
}
