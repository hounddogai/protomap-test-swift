import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy recall allocation calculation.
    protocol LegacyRecallAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyRecallAllocation, value: Double) -> Double
    }

    final class TieredLegacyRecallAllocationAdjuster: LegacyRecallAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyRecallAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLegacyRecallAllocationAdjuster: LegacyRecallAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyRecallAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyRecallAllocationAdjuster: LegacyRecallAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyRecallAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LegacyRecallAllocationPriorityOffsetAdjuster: LegacyRecallAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LegacyRecallAllocation, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the legacy recall allocation steps in order and keeps a trace of each.
    final class LegacyRecallAllocationEngine {
        var steps: [any LegacyRecallAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRecallAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyRecallAllocation) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyRecallAllocationAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyRecallAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyRecallAllocationEngine() -> LegacyRecallAllocationEngine {
        return LegacyRecallAllocationEngine(
            steps: [
                TieredLegacyRecallAllocationAdjuster(bounds: [3397.0, 3481.0, 3597.0], rates: [1.05, 1.04, 0.99]),
                TitleLegacyRecallAllocationAdjuster(factors: ["online": 0.75]),
                MinimumLegacyRecallAllocationAdjuster(minimum: 8.8),
                LegacyRecallAllocationPriorityOffsetAdjuster(weight: 0.6),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 51327.3
        )
    }
}
