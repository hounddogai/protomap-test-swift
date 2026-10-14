import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient charge tier calculation.
    protocol LenientChargeTierModifier {
        func describe() -> String
        func adjust(_ item: LenientChargeTier, value: Double) -> Double
    }

    final class TieredLenientChargeTierAdjuster: LenientChargeTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientChargeTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientChargeTierAdjuster: LenientChargeTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientChargeTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLenientChargeTierAdjuster: LenientChargeTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientChargeTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientChargeTierAdjuster: LenientChargeTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientChargeTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientChargeTierAdjuster: LenientChargeTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientChargeTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient charge tier steps in order and keeps a trace of each.
    final class LenientChargeTierEngine {
        var steps: [any LenientChargeTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientChargeTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientChargeTier) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [LenientChargeTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientChargeTierEngine() -> LenientChargeTierEngine {
        return LenientChargeTierEngine(
            steps: [
                TieredLenientChargeTierAdjuster(bounds: [391.0, 2887.0], rates: [0.89, 0.97]),
                CapLenientChargeTierAdjuster(cap: 26914.0),
                LabelLenientChargeTierAdjuster(factors: ["west": 1.08]),
                MinimumLenientChargeTierAdjuster(minimum: 16.7),
                RoundingLenientChargeTierAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 82524.8
        )
    }
}
