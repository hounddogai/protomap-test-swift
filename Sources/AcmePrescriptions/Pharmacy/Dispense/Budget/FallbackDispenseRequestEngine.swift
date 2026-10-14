import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback dispense request calculation.
    protocol FallbackDispenseRequestModifier {
        func describe() -> String
        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double
    }

    final class MinimumFallbackDispenseRequestAdjuster: FallbackDispenseRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackDispenseRequestQuantityOffsetAdjuster: FallbackDispenseRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CategoryFallbackDispenseRequestAdjuster: FallbackDispenseRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackDispenseRequestAdjuster: FallbackDispenseRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackDispenseRequestAdjuster: FallbackDispenseRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDispenseRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback dispense request steps in order and keeps a trace of each.
    final class FallbackDispenseRequestEngine {
        var steps: [any FallbackDispenseRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDispenseRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackDispenseRequest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackDispenseRequestModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackDispenseRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackDispenseRequestEngine() -> FallbackDispenseRequestEngine {
        return FallbackDispenseRequestEngine(
            steps: [
                MinimumFallbackDispenseRequestAdjuster(minimum: 36.7),
                FallbackDispenseRequestQuantityOffsetAdjuster(weight: 0.59),
                CategoryFallbackDispenseRequestAdjuster(factors: ["north": 1.04]),
                CapFallbackDispenseRequestAdjuster(cap: 24726.0),
                PercentFallbackDispenseRequestAdjuster(percent: 5.4),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 71252.1
        )
    }
}
