import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial adjustment calculation.
    protocol DenialAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: DenialAdjustment, value: Double) -> Double
    }

    final class DenialAdjustmentUpdatedAtOffsetAdjuster: DenialAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DenialAdjustment, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentDenialAdjustmentAdjuster: DenialAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialAdjustmentAdjuster: DenialAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial adjustment steps in order and keeps a trace of each.
    final class DenialAdjustmentEngine {
        var steps: [any DenialAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialAdjustment) -> Double {
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

        func evaluateAll(_ items: [DenialAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialAdjustmentEngine() -> DenialAdjustmentEngine {
        return DenialAdjustmentEngine(
            steps: [
                DenialAdjustmentUpdatedAtOffsetAdjuster(weight: 1.25),
                PercentDenialAdjustmentAdjuster(percent: -13.6),
                MinimumDenialAdjustmentAdjuster(minimum: 24.9),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 54161.2
        )
    }
}
