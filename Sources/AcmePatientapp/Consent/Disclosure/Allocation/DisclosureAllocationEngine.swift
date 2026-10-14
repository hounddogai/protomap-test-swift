import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure allocation calculation.
    protocol DisclosureAllocationModifier {
        func describe() -> String
        func adjust(_ item: DisclosureAllocation, value: Double) -> Double
    }

    final class RoundingDisclosureAllocationAdjuster: DisclosureAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDisclosureAllocationAdjuster: DisclosureAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDisclosureAllocationAdjuster: DisclosureAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the disclosure allocation steps in order and keeps a trace of each.
    final class DisclosureAllocationEngine {
        var steps: [any DisclosureAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureAllocation) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [DisclosureAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureAllocationEngine() -> DisclosureAllocationEngine {
        return DisclosureAllocationEngine(
            steps: [
                RoundingDisclosureAllocationAdjuster(step: 0.5),
                CapDisclosureAllocationAdjuster(cap: 49248.0),
                TieredDisclosureAllocationAdjuster(bounds: [552.0, 5267.0, 9217.0], rates: [0.97, 0.93, 0.98]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 49366.7
        )
    }
}
