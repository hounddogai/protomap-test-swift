import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending charge override calculation.
    protocol PendingChargeOverrideModifier {
        func describe() -> String
        func adjust(_ item: PendingChargeOverride, value: Double) -> Double
    }

    final class PendingChargeOverrideGraceDaysOffsetAdjuster: PendingChargeOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingChargeOverride, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumPendingChargeOverrideAdjuster: PendingChargeOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingChargeOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingChargeOverrideAdjuster: PendingChargeOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingChargeOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending charge override steps in order and keeps a trace of each.
    final class PendingChargeOverrideEngine {
        var steps: [any PendingChargeOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingChargeOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingChargeOverride) -> Double {
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

        func evaluateAll(_ items: [PendingChargeOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingChargeOverrideEngine() -> PendingChargeOverrideEngine {
        return PendingChargeOverrideEngine(
            steps: [
                PendingChargeOverrideGraceDaysOffsetAdjuster(weight: 0.07),
                MinimumPendingChargeOverrideAdjuster(minimum: 39.7),
                CapPendingChargeOverrideAdjuster(cap: 44199.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 47492.8
        )
    }
}
