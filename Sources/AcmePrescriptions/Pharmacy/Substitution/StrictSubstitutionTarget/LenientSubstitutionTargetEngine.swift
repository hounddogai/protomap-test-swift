import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient substitution target calculation.
    protocol LenientSubstitutionTargetStep {
        func describe() -> String
        func adjust(_ item: LenientSubstitutionTarget, value: Double) -> Double
    }

    final class RoundingLenientSubstitutionTargetAdjuster: LenientSubstitutionTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSubstitutionTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientSubstitutionTargetExpiresAtOffsetAdjuster: LenientSubstitutionTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: LenientSubstitutionTarget, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredLenientSubstitutionTargetAdjuster: LenientSubstitutionTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSubstitutionTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient substitution target steps in order and keeps a trace of each.
    final class LenientSubstitutionTargetEngine {
        var steps: [any LenientSubstitutionTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSubstitutionTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientSubstitutionTarget) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [LenientSubstitutionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientSubstitutionTargetEngine() -> LenientSubstitutionTargetEngine {
        return LenientSubstitutionTargetEngine(
            steps: [
                RoundingLenientSubstitutionTargetAdjuster(step: 0.25),
                LenientSubstitutionTargetExpiresAtOffsetAdjuster(weight: 0.92),
                TieredLenientSubstitutionTargetAdjuster(bounds: [2695.0, 8200.0], rates: [0.85, 1.2]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 17505.3
        )
    }
}
