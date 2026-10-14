import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study rule calculation.
    protocol StudyRuleModifier {
        func describe() -> String
        func adjust(_ item: StudyRule, value: Double) -> Double
    }

    final class TieredStudyRuleAdjuster: StudyRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StudyRuleRefillsOffsetAdjuster: StudyRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: StudyRule, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapStudyRuleAdjuster: StudyRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStudyRuleAdjuster: StudyRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStudyRuleAdjuster: StudyRuleModifier {
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

        func adjust(_ item: StudyRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStudyRuleAdjuster: StudyRuleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study rule steps in order and keeps a trace of each.
    final class StudyRuleEngine {
        var steps: [any StudyRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StudyRule) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [StudyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStudyRuleEngine(_ flags: Kit.Flags.Registry) -> StudyRuleEngine {
        return StudyRuleEngine(
            steps: [
                TieredStudyRuleAdjuster(bounds: [1169.0, 3473.0, 6519.0], rates: [0.83, 1.0, 0.89]),
                StudyRuleRefillsOffsetAdjuster(weight: 1.2),
                CapStudyRuleAdjuster(cap: 9808.0),
                MinimumStudyRuleAdjuster(minimum: 35.0),
                FlaggedStudyRuleAdjuster(flags: flags, flag: "study-rule-global", percent: 3.1),
                RoundingStudyRuleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 79135.7
        )
    }
}
