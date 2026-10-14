import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback charge exception calculation.
    protocol FallbackChargeExceptionModifier {
        func describe() -> String
        func adjust(_ item: FallbackChargeException, value: Double) -> Double
    }

    final class CapFallbackChargeExceptionAdjuster: FallbackChargeExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackChargeException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackChargeExceptionAdjuster: FallbackChargeExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackChargeException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackChargeExceptionAdjuster: FallbackChargeExceptionModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackChargeException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback charge exception steps in order and keeps a trace of each.
    final class FallbackChargeExceptionEngine {
        var steps: [any FallbackChargeExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackChargeExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackChargeException) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackChargeExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackChargeException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackChargeExceptionEngine() -> FallbackChargeExceptionEngine {
        return FallbackChargeExceptionEngine(
            steps: [
                CapFallbackChargeExceptionAdjuster(cap: 24377.0),
                RoundingFallbackChargeExceptionAdjuster(step: 0.25),
                TieredFallbackChargeExceptionAdjuster(bounds: [549.0, 7667.0], rates: [1.12, 1.06]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 84353.9
        )
    }
}
