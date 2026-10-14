import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning bundle calculation.
    protocol CleaningBundleAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningBundle, value: Double) -> Double
    }

    final class CleaningBundleBudgetOffsetAdjuster: CleaningBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: CleaningBundle, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapCleaningBundleAdjuster: CleaningBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCleaningBundleAdjuster: CleaningBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCleaningBundleAdjuster: CleaningBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceCleaningBundleAdjuster: CleaningBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CleaningBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the cleaning bundle steps in order and keeps a trace of each.
    final class CleaningBundleEngine {
        var steps: [any CleaningBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CleaningBundle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CleaningBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCleaningBundleEngine() -> CleaningBundleEngine {
        return CleaningBundleEngine(
            steps: [
                CleaningBundleBudgetOffsetAdjuster(weight: 0.01),
                CapCleaningBundleAdjuster(cap: 35578.0),
                TieredCleaningBundleAdjuster(bounds: [2615.0, 6268.0, 6344.0], rates: [1.04, 0.87, 0.99]),
                MinimumCleaningBundleAdjuster(minimum: 41.6),
                SourceCleaningBundleAdjuster(factors: ["north": 1.33, "retail": 0.82, "east": 1.32]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 96323.4
        )
    }
}
