import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling accession record calculation.
    protocol RollingAccessionRecordAdjuster {
        func describe() -> String
        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double
    }

    final class RollingAccessionRecordBudgetOffsetAdjuster: RollingAccessionRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class RegionRollingAccessionRecordAdjuster: RollingAccessionRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingAccessionRecordAdjuster: RollingAccessionRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingAccessionRecordAdjuster: RollingAccessionRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingAccessionRecordAdjuster: RollingAccessionRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAccessionRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling accession record steps in order and keeps a trace of each.
    final class RollingAccessionRecordEngine {
        var steps: [any RollingAccessionRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAccessionRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingAccessionRecord) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RollingAccessionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingAccessionRecordEngine() -> RollingAccessionRecordEngine {
        return RollingAccessionRecordEngine(
            steps: [
                RollingAccessionRecordBudgetOffsetAdjuster(weight: 0.87),
                RegionRollingAccessionRecordAdjuster(factors: ["retail": 1.31]),
                CapRollingAccessionRecordAdjuster(cap: 23663.0),
                MinimumRollingAccessionRecordAdjuster(minimum: 18.4),
                TieredRollingAccessionRecordAdjuster(bounds: [5873.0, 8363.0, 9597.0], rates: [1.05, 0.99, 1.12]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 50275.6
        )
    }
}
