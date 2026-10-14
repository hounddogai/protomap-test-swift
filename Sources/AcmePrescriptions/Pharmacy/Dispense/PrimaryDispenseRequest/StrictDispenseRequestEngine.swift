import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict dispense request calculation.
    protocol StrictDispenseRequestFactor {
        func describe() -> String
        func adjust(_ item: StrictDispenseRequest, value: Double) -> Double
    }

    final class RoundingStrictDispenseRequestAdjuster: StrictDispenseRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictDispenseRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictDispenseRequestCostOffsetAdjuster: StrictDispenseRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: StrictDispenseRequest, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredStrictDispenseRequestAdjuster: StrictDispenseRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictDispenseRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict dispense request steps in order and keeps a trace of each.
    final class StrictDispenseRequestEngine {
        var steps: [any StrictDispenseRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDispenseRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictDispenseRequest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictDispenseRequestFactor = steps[index]
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

        func evaluateAll(_ items: [StrictDispenseRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictDispenseRequestEngine() -> StrictDispenseRequestEngine {
        return StrictDispenseRequestEngine(
            steps: [
                RoundingStrictDispenseRequestAdjuster(step: 0.5),
                StrictDispenseRequestCostOffsetAdjuster(weight: 1.76),
                TieredStrictDispenseRequestAdjuster(
                    bounds: [1421.0, 4412.0, 4706.0, 5060.0],
                    rates: [1.05, 0.86, 1.02, 1.18]
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 33644.9
        )
    }
}
