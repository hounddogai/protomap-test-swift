import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal accession rollup calculation.
    protocol SeasonalAccessionRollupModifier {
        func describe() -> String
        func adjust(_ item: SeasonalAccessionRollup, value: Double) -> Double
    }

    final class SegmentSeasonalAccessionRollupAdjuster: SeasonalAccessionRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SeasonalAccessionRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalAccessionRollupDiscountOffsetAdjuster: SeasonalAccessionRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: SeasonalAccessionRollup, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CapSeasonalAccessionRollupAdjuster: SeasonalAccessionRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalAccessionRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalAccessionRollupAdjuster: SeasonalAccessionRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalAccessionRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal accession rollup steps in order and keeps a trace of each.
    final class SeasonalAccessionRollupEngine {
        var steps: [any SeasonalAccessionRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAccessionRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalAccessionRollup) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [SeasonalAccessionRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalAccessionRollupEngine() -> SeasonalAccessionRollupEngine {
        return SeasonalAccessionRollupEngine(
            steps: [
                SegmentSeasonalAccessionRollupAdjuster(factors: ["west": 0.95]),
                SeasonalAccessionRollupDiscountOffsetAdjuster(weight: 0.72),
                CapSeasonalAccessionRollupAdjuster(cap: 48890.0),
                MinimumSeasonalAccessionRollupAdjuster(minimum: 47.8),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 54076.6
        )
    }
}
