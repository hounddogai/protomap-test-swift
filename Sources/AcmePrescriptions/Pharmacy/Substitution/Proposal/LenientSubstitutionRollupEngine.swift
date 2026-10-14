import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient substitution rollup calculation.
    protocol LenientSubstitutionRollupStep {
        func describe() -> String
        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double
    }

    final class MinimumLenientSubstitutionRollupAdjuster: LenientSubstitutionRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientSubstitutionRollupAdjuster: LenientSubstitutionRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceLenientSubstitutionRollupAdjuster: LenientSubstitutionRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLenientSubstitutionRollupAdjuster: LenientSubstitutionRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientSubstitutionRollupMarginOffsetAdjuster: LenientSubstitutionRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: LenientSubstitutionRollup, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the lenient substitution rollup steps in order and keeps a trace of each.
    final class LenientSubstitutionRollupEngine {
        var steps: [any LenientSubstitutionRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSubstitutionRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientSubstitutionRollup) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LenientSubstitutionRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientSubstitutionRollupEngine() -> LenientSubstitutionRollupEngine {
        return LenientSubstitutionRollupEngine(
            steps: [
                MinimumLenientSubstitutionRollupAdjuster(minimum: 23.0),
                PercentLenientSubstitutionRollupAdjuster(percent: -15.8),
                SourceLenientSubstitutionRollupAdjuster(factors: ["north": 1.34]),
                TieredLenientSubstitutionRollupAdjuster(
                    bounds: [489.0, 4787.0, 6897.0, 8249.0],
                    rates: [0.8, 1.18, 1.1, 1.0]
                ),
                LenientSubstitutionRollupMarginOffsetAdjuster(weight: 0.19),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 7138.0
        )
    }
}
