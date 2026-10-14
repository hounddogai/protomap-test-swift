import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped study allocation calculation.
    protocol CappedStudyAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: CappedStudyAllocation, value: Double) -> Double
    }

    final class MinimumCappedStudyAllocationAdjuster: CappedStudyAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedStudyAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryCappedStudyAllocationAdjuster: CappedStudyAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CappedStudyAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedStudyAllocationAdjuster: CappedStudyAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedStudyAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCappedStudyAllocationAdjuster: CappedStudyAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedStudyAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped study allocation steps in order and keeps a trace of each.
    final class CappedStudyAllocationEngine {
        var steps: [any CappedStudyAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStudyAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedStudyAllocation) -> Double {
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

        func evaluateAll(_ items: [CappedStudyAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedStudyAllocationEngine() -> CappedStudyAllocationEngine {
        return CappedStudyAllocationEngine(
            steps: [
                MinimumCappedStudyAllocationAdjuster(minimum: 43.2),
                CountryCappedStudyAllocationAdjuster(factors: ["east": 1.35]),
                TieredCappedStudyAllocationAdjuster(bounds: [1883.0, 1890.0, 2153.0], rates: [1.06, 1.09, 0.91]),
                PercentCappedStudyAllocationAdjuster(percent: -8.1),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 34166.5
        )
    }
}
