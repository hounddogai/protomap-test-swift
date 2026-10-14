import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution score calculation.
    protocol SubstitutionScoreModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionScore, value: Double) -> Double
    }

    final class CapSubstitutionScoreAdjuster: SubstitutionScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSubstitutionScoreAdjuster: SubstitutionScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSubstitutionScoreAdjuster: SubstitutionScoreModifier {
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

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameSubstitutionScoreAdjuster: SubstitutionScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSubstitutionScoreAdjuster: SubstitutionScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SubstitutionScoreExpiresAtOffsetAdjuster: SubstitutionScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: SubstitutionScore, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the substitution score steps in order and keeps a trace of each.
    final class SubstitutionScoreEngine {
        var steps: [any SubstitutionScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionScore) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [SubstitutionScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionScoreEngine(_ flags: Kit.Flags.Registry) -> SubstitutionScoreEngine {
        return SubstitutionScoreEngine(
            steps: [
                CapSubstitutionScoreAdjuster(cap: 8531.0),
                MinimumSubstitutionScoreAdjuster(minimum: 4.4),
                FlaggedSubstitutionScoreAdjuster(flags: flags, flag: "substitution-score-regional", percent: 9.8),
                NameSubstitutionScoreAdjuster(factors: ["south": 1.25]),
                RoundingSubstitutionScoreAdjuster(step: 0.1),
                SubstitutionScoreExpiresAtOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 47049.6
        )
    }
}
