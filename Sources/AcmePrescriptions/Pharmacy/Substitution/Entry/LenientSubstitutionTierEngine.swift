import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient substitution tier calculation.
    protocol LenientSubstitutionTierStep {
        func describe() -> String
        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double
    }

    final class RoundingLenientSubstitutionTierAdjuster: LenientSubstitutionTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientSubstitutionTierAdjuster: LenientSubstitutionTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientSubstitutionTierAdjuster: LenientSubstitutionTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientSubstitutionTierAdjuster: LenientSubstitutionTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LenientSubstitutionTierThresholdOffsetAdjuster: LenientSubstitutionTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientSubstitutionTier, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the lenient substitution tier steps in order and keeps a trace of each.
    final class LenientSubstitutionTierEngine {
        var steps: [any LenientSubstitutionTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSubstitutionTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientSubstitutionTier) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSubstitutionTierStep = steps[index]
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

        func evaluateAll(_ items: [LenientSubstitutionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientSubstitutionTierEngine() -> LenientSubstitutionTierEngine {
        return LenientSubstitutionTierEngine(
            steps: [
                RoundingLenientSubstitutionTierAdjuster(step: 0.1),
                CapLenientSubstitutionTierAdjuster(cap: 31448.0),
                TitleLenientSubstitutionTierAdjuster(factors: ["central": 1.05]),
                MinimumLenientSubstitutionTierAdjuster(minimum: 5.3),
                LenientSubstitutionTierThresholdOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 5809.3
        )
    }
}
