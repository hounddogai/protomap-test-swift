import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge threshold calculation.
    protocol CappedChargeThresholdModifier {
        func describe() -> String
        func adjust(_ item: CappedChargeThreshold, value: Double) -> Double
    }

    final class MinimumCappedChargeThresholdAdjuster: CappedChargeThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedChargeThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedChargeThresholdAdjuster: CappedChargeThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedChargeThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryCappedChargeThresholdAdjuster: CappedChargeThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CappedChargeThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedChargeThresholdAdjuster: CappedChargeThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedChargeThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped charge threshold steps in order and keeps a trace of each.
    final class CappedChargeThresholdEngine {
        var steps: [any CappedChargeThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedChargeThreshold) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedChargeThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [CappedChargeThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedChargeThresholdEngine() -> CappedChargeThresholdEngine {
        return CappedChargeThresholdEngine(
            steps: [
                MinimumCappedChargeThresholdAdjuster(minimum: 39.8),
                CapCappedChargeThresholdAdjuster(cap: 28944.0),
                CategoryCappedChargeThresholdAdjuster(factors: ["north": 1.12, "east": 1.37]),
                PercentCappedChargeThresholdAdjuster(percent: -7.5),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 63335.5
        )
    }
}
