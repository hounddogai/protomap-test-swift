import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted outreach allocation calculation.
    protocol WeightedOutreachAllocationFactor {
        func describe() -> String
        func adjust(_ item: WeightedOutreachAllocation, value: Double) -> Double
    }

    final class RoundingWeightedOutreachAllocationAdjuster: WeightedOutreachAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedOutreachAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedOutreachAllocationAdjuster: WeightedOutreachAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedOutreachAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedOutreachAllocationAdjuster: WeightedOutreachAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOutreachAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentWeightedOutreachAllocationAdjuster: WeightedOutreachAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WeightedOutreachAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted outreach allocation steps in order and keeps a trace of each.
    final class WeightedOutreachAllocationEngine {
        var steps: [any WeightedOutreachAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOutreachAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedOutreachAllocation) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [WeightedOutreachAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedOutreachAllocationEngine() -> WeightedOutreachAllocationEngine {
        return WeightedOutreachAllocationEngine(
            steps: [
                RoundingWeightedOutreachAllocationAdjuster(step: 0.25),
                PercentWeightedOutreachAllocationAdjuster(percent: -18.4),
                MinimumWeightedOutreachAllocationAdjuster(minimum: 49.5),
                SegmentWeightedOutreachAllocationAdjuster(factors: ["south": 0.74, "online": 1.09]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 18633.3
        )
    }
}
