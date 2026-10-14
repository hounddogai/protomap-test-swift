import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert tier calculation.
    protocol AlertTierAdjuster {
        func describe() -> String
        func adjust(_ item: AlertTier, value: Double) -> Double
    }

    final class MinimumAlertTierAdjuster: AlertTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AlertTierWeightOffsetAdjuster: AlertTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: AlertTier, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class RoundingAlertTierAdjuster: AlertTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the alert tier steps in order and keeps a trace of each.
    final class AlertTierEngine {
        var steps: [any AlertTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertTier) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [AlertTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertTierEngine() -> AlertTierEngine {
        return AlertTierEngine(
            steps: [
                MinimumAlertTierAdjuster(minimum: 49.3),
                AlertTierWeightOffsetAdjuster(weight: 1.9),
                RoundingAlertTierAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 59135.6
        )
    }
}
