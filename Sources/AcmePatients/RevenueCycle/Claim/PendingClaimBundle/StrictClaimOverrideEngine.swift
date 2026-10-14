import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict claim override calculation.
    protocol StrictClaimOverrideModifier {
        func describe() -> String
        func adjust(_ item: StrictClaimOverride, value: Double) -> Double
    }

    final class PercentStrictClaimOverrideAdjuster: StrictClaimOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictClaimOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictClaimOverrideAdjuster: StrictClaimOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictClaimOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictClaimOverrideCeilingOffsetAdjuster: StrictClaimOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: StrictClaimOverride, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the strict claim override steps in order and keeps a trace of each.
    final class StrictClaimOverrideEngine {
        var steps: [any StrictClaimOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictClaimOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictClaimOverride) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [StrictClaimOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictClaimOverrideEngine() -> StrictClaimOverrideEngine {
        return StrictClaimOverrideEngine(
            steps: [
                PercentStrictClaimOverrideAdjuster(percent: 15.6),
                CapStrictClaimOverrideAdjuster(cap: 31347.0),
                StrictClaimOverrideCeilingOffsetAdjuster(weight: 1.29),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 84743.7
        )
    }
}
