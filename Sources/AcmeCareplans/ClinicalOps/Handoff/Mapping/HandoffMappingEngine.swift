import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff mapping calculation.
    protocol HandoffMappingModifier {
        func describe() -> String
        func adjust(_ item: HandoffMapping, value: Double) -> Double
    }

    final class TieredHandoffMappingAdjuster: HandoffMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingHandoffMappingAdjuster: HandoffMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class HandoffMappingCopayOffsetAdjuster: HandoffMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: HandoffMapping, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the handoff mapping steps in order and keeps a trace of each.
    final class HandoffMappingEngine {
        var steps: [any HandoffMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffMapping) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffMappingModifier = steps[index]
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

        func evaluateAll(_ items: [HandoffMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffMappingEngine() -> HandoffMappingEngine {
        return HandoffMappingEngine(
            steps: [
                TieredHandoffMappingAdjuster(
                    bounds: [1565.0, 5943.0, 7668.0, 8205.0],
                    rates: [1.06, 0.97, 1.08, 0.87]
                ),
                RoundingHandoffMappingAdjuster(step: 0.05),
                HandoffMappingCopayOffsetAdjuster(weight: 1.38),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 9774.4
        )
    }
}
