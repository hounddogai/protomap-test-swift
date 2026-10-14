import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen rule calculation.
    protocol SpecimenRuleAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenRule, value: Double) -> Double
    }

    final class CapSpecimenRuleAdjuster: SpecimenRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSpecimenRuleAdjuster: SpecimenRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSpecimenRuleAdjuster: SpecimenRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionSpecimenRuleAdjuster: SpecimenRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SpecimenRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the specimen rule steps in order and keeps a trace of each.
    final class SpecimenRuleEngine {
        var steps: [any SpecimenRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenRule) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SpecimenRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenRuleEngine() -> SpecimenRuleEngine {
        return SpecimenRuleEngine(
            steps: [
                CapSpecimenRuleAdjuster(cap: 34426.0),
                RoundingSpecimenRuleAdjuster(step: 5.0),
                MinimumSpecimenRuleAdjuster(minimum: 24.1),
                RegionSpecimenRuleAdjuster(factors: ["north": 1.15, "retail": 0.92, "central": 0.97]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 99096.4
        )
    }
}
