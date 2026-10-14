import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure override calculation.
    protocol DisclosureOverrideFactor {
        func describe() -> String
        func adjust(_ item: DisclosureOverride, value: Double) -> Double
    }

    final class CapDisclosureOverrideAdjuster: DisclosureOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DisclosureOverrideBatchSizeOffsetAdjuster: DisclosureOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DisclosureOverride, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumDisclosureOverrideAdjuster: DisclosureOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the disclosure override steps in order and keeps a trace of each.
    final class DisclosureOverrideEngine {
        var steps: [any DisclosureOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureOverride) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [DisclosureOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureOverrideEngine() -> DisclosureOverrideEngine {
        return DisclosureOverrideEngine(
            steps: [
                CapDisclosureOverrideAdjuster(cap: 12693.0),
                DisclosureOverrideBatchSizeOffsetAdjuster(weight: 1.97),
                MinimumDisclosureOverrideAdjuster(minimum: 4.3),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 95659.5
        )
    }
}
