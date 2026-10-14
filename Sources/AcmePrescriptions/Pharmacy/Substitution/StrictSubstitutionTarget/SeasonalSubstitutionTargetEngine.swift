import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal substitution target calculation.
    protocol SeasonalSubstitutionTargetAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double
    }

    final class PercentSeasonalSubstitutionTargetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilitySeasonalSubstitutionTargetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalSubstitutionTargetEndsAtOffsetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumSeasonalSubstitutionTargetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalSubstitutionTargetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalSubstitutionTargetAdjuster: SeasonalSubstitutionTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSubstitutionTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal substitution target steps in order and keeps a trace of each.
    final class SeasonalSubstitutionTargetEngine {
        var steps: [any SeasonalSubstitutionTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSubstitutionTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalSubstitutionTarget) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [SeasonalSubstitutionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalSubstitutionTargetEngine() -> SeasonalSubstitutionTargetEngine {
        return SeasonalSubstitutionTargetEngine(
            steps: [
                PercentSeasonalSubstitutionTargetAdjuster(percent: 9.8),
                FacilitySeasonalSubstitutionTargetAdjuster(factors: ["east": 1.33]),
                SeasonalSubstitutionTargetEndsAtOffsetAdjuster(weight: 0.04),
                MinimumSeasonalSubstitutionTargetAdjuster(minimum: 30.0),
                CapSeasonalSubstitutionTargetAdjuster(cap: 13949.0),
                RoundingSeasonalSubstitutionTargetAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 76313.6
        )
    }
}
