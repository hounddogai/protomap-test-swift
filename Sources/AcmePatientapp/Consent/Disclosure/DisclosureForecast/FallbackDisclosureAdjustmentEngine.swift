import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback disclosure adjustment calculation.
    protocol FallbackDisclosureAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: FallbackDisclosureAdjustment, value: Double) -> Double
    }

    final class RoundingFallbackDisclosureAdjustmentAdjuster: FallbackDisclosureAdjustmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackDisclosureAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackDisclosureAdjustmentPriorityOffsetAdjuster: FallbackDisclosureAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: FallbackDisclosureAdjustment, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumFallbackDisclosureAdjustmentAdjuster: FallbackDisclosureAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDisclosureAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackDisclosureAdjustmentAdjuster: FallbackDisclosureAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDisclosureAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback disclosure adjustment steps in order and keeps a trace of each.
    final class FallbackDisclosureAdjustmentEngine {
        var steps: [any FallbackDisclosureAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDisclosureAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackDisclosureAdjustment) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FallbackDisclosureAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackDisclosureAdjustmentEngine() -> FallbackDisclosureAdjustmentEngine {
        return FallbackDisclosureAdjustmentEngine(
            steps: [
                RoundingFallbackDisclosureAdjustmentAdjuster(step: 0.5),
                FallbackDisclosureAdjustmentPriorityOffsetAdjuster(weight: 0.13),
                MinimumFallbackDisclosureAdjustmentAdjuster(minimum: 17.7),
                PercentFallbackDisclosureAdjustmentAdjuster(percent: 16.7),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 36182.1
        )
    }
}
