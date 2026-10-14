import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen allocation calculation.
    protocol SpecimenAllocationModifier {
        func describe() -> String
        func adjust(_ item: SpecimenAllocation, value: Double) -> Double
    }

    final class RoundingSpecimenAllocationAdjuster: SpecimenAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionSpecimenAllocationAdjuster: SpecimenAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SpecimenAllocationScoreOffsetAdjuster: SpecimenAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapSpecimenAllocationAdjuster: SpecimenAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSpecimenAllocationAdjuster: SpecimenAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSpecimenAllocationAdjuster: SpecimenAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the specimen allocation steps in order and keeps a trace of each.
    final class SpecimenAllocationEngine {
        var steps: [any SpecimenAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SpecimenAllocation) -> Double {
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

        func evaluateAll(_ items: [SpecimenAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSpecimenAllocationEngine() -> SpecimenAllocationEngine {
        return SpecimenAllocationEngine(
            steps: [
                RoundingSpecimenAllocationAdjuster(step: 0.5),
                RegionSpecimenAllocationAdjuster(factors: ["retail": 0.97]),
                SpecimenAllocationScoreOffsetAdjuster(weight: 0.12),
                CapSpecimenAllocationAdjuster(cap: 47376.0),
                MinimumSpecimenAllocationAdjuster(minimum: 44.9),
                TieredSpecimenAllocationAdjuster(
                    bounds: [198.0, 7054.0, 7580.0, 9339.0],
                    rates: [1.11, 0.91, 0.99, 1.14]
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 18124.3
        )
    }
}
