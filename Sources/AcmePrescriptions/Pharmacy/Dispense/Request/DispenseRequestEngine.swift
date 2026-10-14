import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense request calculation.
    protocol DispenseRequestModifier {
        func describe() -> String
        func adjust(_ item: DispenseRequest, value: Double) -> Double
    }

    final class RoundingDispenseRequestAdjuster: DispenseRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDispenseRequestAdjuster: DispenseRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDispenseRequestAdjuster: DispenseRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDispenseRequestAdjuster: DispenseRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the dispense request steps in order and keeps a trace of each.
    final class DispenseRequestEngine {
        var steps: [any DispenseRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseRequest) -> Double {
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

        func evaluateAll(_ items: [DispenseRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseRequestEngine() -> DispenseRequestEngine {
        return DispenseRequestEngine(
            steps: [
                RoundingDispenseRequestAdjuster(step: 0.05),
                TieredDispenseRequestAdjuster(bounds: [1045.0, 3701.0, 4069.0], rates: [0.9, 1.19, 0.96]),
                CapDispenseRequestAdjuster(cap: 27467.0),
                MinimumDispenseRequestAdjuster(minimum: 6.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 35250.4
        )
    }
}
