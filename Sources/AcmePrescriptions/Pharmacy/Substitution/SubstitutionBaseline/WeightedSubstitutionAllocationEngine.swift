import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted substitution allocation calculation.
    protocol WeightedSubstitutionAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double
    }

    final class MinimumWeightedSubstitutionAllocationAdjuster: WeightedSubstitutionAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedSubstitutionAllocationStartsAtOffsetAdjuster: WeightedSubstitutionAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class SourceWeightedSubstitutionAllocationAdjuster: WeightedSubstitutionAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedSubstitutionAllocationAdjuster: WeightedSubstitutionAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedSubstitutionAllocationAdjuster: WeightedSubstitutionAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedSubstitutionAllocationAdjuster: WeightedSubstitutionAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSubstitutionAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted substitution allocation steps in order and keeps a trace of each.
    final class WeightedSubstitutionAllocationEngine {
        var steps: [any WeightedSubstitutionAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSubstitutionAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedSubstitutionAllocation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSubstitutionAllocationAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedSubstitutionAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedSubstitutionAllocationEngine() -> WeightedSubstitutionAllocationEngine {
        return WeightedSubstitutionAllocationEngine(
            steps: [
                MinimumWeightedSubstitutionAllocationAdjuster(minimum: 0.9),
                WeightedSubstitutionAllocationStartsAtOffsetAdjuster(weight: 1.37),
                SourceWeightedSubstitutionAllocationAdjuster(factors: ["south": 1.28, "retail": 0.94]),
                TieredWeightedSubstitutionAllocationAdjuster(
                    bounds: [1210.0, 6659.0, 7882.0, 8222.0],
                    rates: [0.95, 1.07, 1.12, 1.17]
                ),
                CapWeightedSubstitutionAllocationAdjuster(cap: 8993.0),
                RoundingWeightedSubstitutionAllocationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 38303.6
        )
    }
}
