import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict reference range rollup calculation.
    protocol StrictReferenceRangeRollupModifier {
        func describe() -> String
        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double
    }

    final class PercentStrictReferenceRangeRollupAdjuster: StrictReferenceRangeRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictReferenceRangeRollupAdjuster: StrictReferenceRangeRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictReferenceRangeRollupExpiresAtOffsetAdjuster: StrictReferenceRangeRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumStrictReferenceRangeRollupAdjuster: StrictReferenceRangeRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitStrictReferenceRangeRollupAdjuster: StrictReferenceRangeRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictReferenceRangeRollupAdjuster: StrictReferenceRangeRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReferenceRangeRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict reference range rollup steps in order and keeps a trace of each.
    final class StrictReferenceRangeRollupEngine {
        var steps: [any StrictReferenceRangeRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReferenceRangeRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictReferenceRangeRollup) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [StrictReferenceRangeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictReferenceRangeRollupEngine() -> StrictReferenceRangeRollupEngine {
        return StrictReferenceRangeRollupEngine(
            steps: [
                PercentStrictReferenceRangeRollupAdjuster(percent: -11.3),
                RoundingStrictReferenceRangeRollupAdjuster(step: 0.05),
                StrictReferenceRangeRollupExpiresAtOffsetAdjuster(weight: 1.25),
                MinimumStrictReferenceRangeRollupAdjuster(minimum: 31.2),
                UnitStrictReferenceRangeRollupAdjuster(factors: ["online": 1.04]),
                TieredStrictReferenceRangeRollupAdjuster(bounds: [1635.0, 6245.0, 9189.0], rates: [0.88, 1.07, 0.99]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 62851.2
        )
    }
}
