import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure group calculation.
    protocol DisclosureGroupModifier {
        func describe() -> String
        func adjust(_ item: DisclosureGroup, value: Double) -> Double
    }

    final class PercentDisclosureGroupAdjuster: DisclosureGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDisclosureGroupAdjuster: DisclosureGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelDisclosureGroupAdjuster: DisclosureGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DisclosureGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDisclosureGroupAdjuster: DisclosureGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the disclosure group steps in order and keeps a trace of each.
    final class DisclosureGroupEngine {
        var steps: [any DisclosureGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureGroup) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [DisclosureGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureGroupEngine() -> DisclosureGroupEngine {
        return DisclosureGroupEngine(
            steps: [
                PercentDisclosureGroupAdjuster(percent: 8.1),
                RoundingDisclosureGroupAdjuster(step: 0.05),
                LabelDisclosureGroupAdjuster(factors: ["south": 0.84, "online": 0.81]),
                MinimumDisclosureGroupAdjuster(minimum: 12.9),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 67244.4
        )
    }
}
