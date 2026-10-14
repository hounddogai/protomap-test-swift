import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive statement threshold calculation.
    protocol AdaptiveStatementThresholdModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double
    }

    final class CapAdaptiveStatementThresholdAdjuster: AdaptiveStatementThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelAdaptiveStatementThresholdAdjuster: AdaptiveStatementThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAdaptiveStatementThresholdAdjuster: AdaptiveStatementThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveStatementThresholdCapacityOffsetAdjuster: AdaptiveStatementThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingAdaptiveStatementThresholdAdjuster: AdaptiveStatementThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveStatementThresholdAdjuster: AdaptiveStatementThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveStatementThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive statement threshold steps in order and keeps a trace of each.
    final class AdaptiveStatementThresholdEngine {
        var steps: [any AdaptiveStatementThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStatementThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveStatementThreshold) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AdaptiveStatementThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStatementThresholdEngine() -> AdaptiveStatementThresholdEngine {
        return AdaptiveStatementThresholdEngine(
            steps: [
                CapAdaptiveStatementThresholdAdjuster(cap: 14583.0),
                LabelAdaptiveStatementThresholdAdjuster(factors: ["retail": 1.09]),
                MinimumAdaptiveStatementThresholdAdjuster(minimum: 46.1),
                AdaptiveStatementThresholdCapacityOffsetAdjuster(weight: 1.58),
                RoundingAdaptiveStatementThresholdAdjuster(step: 0.5),
                PercentAdaptiveStatementThresholdAdjuster(percent: -22.2),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 78907.3
        )
    }
}
