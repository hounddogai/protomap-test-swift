import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness rule calculation.
    protocol WitnessRuleModifier {
        func describe() -> String
        func adjust(_ item: WitnessRule, value: Double) -> Double
    }

    final class WitnessRuleRetriesOffsetAdjuster: WitnessRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: WitnessRule, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class RoundingWitnessRuleAdjuster: WitnessRuleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWitnessRuleAdjuster: WitnessRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleWitnessRuleAdjuster: WitnessRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WitnessRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the witness rule steps in order and keeps a trace of each.
    final class WitnessRuleEngine {
        var steps: [any WitnessRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessRule) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessRuleModifier = steps[index]
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

        func evaluateAll(_ items: [WitnessRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessRuleEngine() -> WitnessRuleEngine {
        return WitnessRuleEngine(
            steps: [
                WitnessRuleRetriesOffsetAdjuster(weight: 1.87),
                RoundingWitnessRuleAdjuster(step: 0.5),
                CapWitnessRuleAdjuster(cap: 41589.0),
                TitleWitnessRuleAdjuster(factors: ["north": 1.39, "online": 0.97]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 57656.2
        )
    }
}
