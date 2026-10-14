import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback assessment allocation calculation.
    protocol FallbackAssessmentAllocationModifier {
        func describe() -> String
        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double
    }

    final class RoundingFallbackAssessmentAllocationAdjuster: FallbackAssessmentAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackAssessmentAllocationAdjuster: FallbackAssessmentAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackAssessmentAllocationQuantityOffsetAdjuster: FallbackAssessmentAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredFallbackAssessmentAllocationAdjuster: FallbackAssessmentAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackAssessmentAllocationAdjuster: FallbackAssessmentAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAssessmentAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback assessment allocation steps in order and keeps a trace of each.
    final class FallbackAssessmentAllocationEngine {
        var steps: [any FallbackAssessmentAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAssessmentAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAssessmentAllocation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAssessmentAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackAssessmentAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAssessmentAllocationEngine() -> FallbackAssessmentAllocationEngine {
        return FallbackAssessmentAllocationEngine(
            steps: [
                RoundingFallbackAssessmentAllocationAdjuster(step: 0.25),
                CapFallbackAssessmentAllocationAdjuster(cap: 16802.0),
                FallbackAssessmentAllocationQuantityOffsetAdjuster(weight: 1.44),
                TieredFallbackAssessmentAllocationAdjuster(
                    bounds: [932.0, 4552.0, 5866.0, 7247.0],
                    rates: [0.93, 0.88, 0.93, 0.92]
                ),
                MinimumFallbackAssessmentAllocationAdjuster(minimum: 1.4),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 61798.5
        )
    }
}
