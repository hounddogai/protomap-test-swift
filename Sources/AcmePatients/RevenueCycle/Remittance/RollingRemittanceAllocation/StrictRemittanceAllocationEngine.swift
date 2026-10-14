import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict remittance allocation calculation.
    protocol StrictRemittanceAllocationModifier {
        func describe() -> String
        func adjust(_ item: StrictRemittanceAllocation, value: Double) -> Double
    }

    final class StrictRemittanceAllocationCapacityOffsetAdjuster: StrictRemittanceAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: StrictRemittanceAllocation, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingStrictRemittanceAllocationAdjuster: StrictRemittanceAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictRemittanceAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictRemittanceAllocationAdjuster: StrictRemittanceAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictRemittanceAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictRemittanceAllocationAdjuster: StrictRemittanceAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictRemittanceAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict remittance allocation steps in order and keeps a trace of each.
    final class StrictRemittanceAllocationEngine {
        var steps: [any StrictRemittanceAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictRemittanceAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictRemittanceAllocation) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StrictRemittanceAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictRemittanceAllocationEngine() -> StrictRemittanceAllocationEngine {
        return StrictRemittanceAllocationEngine(
            steps: [
                StrictRemittanceAllocationCapacityOffsetAdjuster(weight: 0.6),
                RoundingStrictRemittanceAllocationAdjuster(step: 1.0),
                TieredStrictRemittanceAllocationAdjuster(
                    bounds: [478.0, 4004.0, 5881.0, 9868.0],
                    rates: [0.97, 1.19, 0.81, 0.95]
                ),
                MinimumStrictRemittanceAllocationAdjuster(minimum: 1.9),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 24285.1
        )
    }
}
