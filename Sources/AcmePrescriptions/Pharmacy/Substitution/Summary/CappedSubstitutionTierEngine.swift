import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped substitution tier calculation.
    protocol CappedSubstitutionTierStep {
        func describe() -> String
        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double
    }

    final class PercentCappedSubstitutionTierAdjuster: CappedSubstitutionTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedSubstitutionTierAmountOffsetAdjuster: CappedSubstitutionTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapCappedSubstitutionTierAdjuster: CappedSubstitutionTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionCappedSubstitutionTierAdjuster: CappedSubstitutionTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedSubstitutionTierAdjuster: CappedSubstitutionTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedSubstitutionTierAdjuster: CappedSubstitutionTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSubstitutionTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped substitution tier steps in order and keeps a trace of each.
    final class CappedSubstitutionTierEngine {
        var steps: [any CappedSubstitutionTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSubstitutionTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedSubstitutionTier) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedSubstitutionTierStep = steps[index]
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

        func evaluateAll(_ items: [CappedSubstitutionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedSubstitutionTierEngine() -> CappedSubstitutionTierEngine {
        return CappedSubstitutionTierEngine(
            steps: [
                PercentCappedSubstitutionTierAdjuster(percent: 18.0),
                CappedSubstitutionTierAmountOffsetAdjuster(weight: 0.66),
                CapCappedSubstitutionTierAdjuster(cap: 10768.0),
                RegionCappedSubstitutionTierAdjuster(factors: ["west": 0.8, "online": 1.33]),
                RoundingCappedSubstitutionTierAdjuster(step: 0.25),
                MinimumCappedSubstitutionTierAdjuster(minimum: 20.7),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 59445.2
        )
    }
}
