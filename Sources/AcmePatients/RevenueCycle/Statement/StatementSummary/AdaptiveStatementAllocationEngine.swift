import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive statement allocation calculation.
    protocol AdaptiveStatementAllocationModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double
    }

    final class RoundingAdaptiveStatementAllocationAdjuster: AdaptiveStatementAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveStatementAllocationAdjuster: AdaptiveStatementAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveStatementAllocationDurationMinutesOffsetAdjuster: AdaptiveStatementAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumAdaptiveStatementAllocationAdjuster: AdaptiveStatementAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveStatementAllocationAdjuster: AdaptiveStatementAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveStatementAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive statement allocation steps in order and keeps a trace of each.
    final class AdaptiveStatementAllocationEngine {
        var steps: [any AdaptiveStatementAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStatementAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveStatementAllocation) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveStatementAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveStatementAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStatementAllocationEngine() -> AdaptiveStatementAllocationEngine {
        return AdaptiveStatementAllocationEngine(
            steps: [
                RoundingAdaptiveStatementAllocationAdjuster(step: 0.05),
                TieredAdaptiveStatementAllocationAdjuster(
                    bounds: [1233.0, 5293.0, 6784.0, 8792.0],
                    rates: [1.19, 0.94, 0.81, 0.92]
                ),
                AdaptiveStatementAllocationDurationMinutesOffsetAdjuster(weight: 0.61),
                MinimumAdaptiveStatementAllocationAdjuster(minimum: 49.3),
                CapAdaptiveStatementAllocationAdjuster(cap: 41353.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 58701.2
        )
    }
}
