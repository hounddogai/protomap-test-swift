import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient inventory override calculation.
    protocol LenientInventoryOverrideStep {
        func describe() -> String
        func adjust(_ item: LenientInventoryOverride, value: Double) -> Double
    }

    final class CapLenientInventoryOverrideAdjuster: LenientInventoryOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientInventoryOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientInventoryOverrideAdjuster: LenientInventoryOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientInventoryOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientInventoryOverrideAdjuster: LenientInventoryOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientInventoryOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient inventory override steps in order and keeps a trace of each.
    final class LenientInventoryOverrideEngine {
        var steps: [any LenientInventoryOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientInventoryOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientInventoryOverride) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [LenientInventoryOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientInventoryOverrideEngine() -> LenientInventoryOverrideEngine {
        return LenientInventoryOverrideEngine(
            steps: [
                CapLenientInventoryOverrideAdjuster(cap: 9262.0),
                MinimumLenientInventoryOverrideAdjuster(minimum: 24.9),
                PercentLenientInventoryOverrideAdjuster(percent: -17.2),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 65824.9
        )
    }
}
