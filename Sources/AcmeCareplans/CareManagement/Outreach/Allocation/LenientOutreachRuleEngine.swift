import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient outreach rule calculation.
    protocol LenientOutreachRuleModifier {
        func describe() -> String
        func adjust(_ item: LenientOutreachRule, value: Double) -> Double
    }

    final class CapLenientOutreachRuleAdjuster: LenientOutreachRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOutreachRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientOutreachRulePriorityOffsetAdjuster: LenientOutreachRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LenientOutreachRule, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class NameLenientOutreachRuleAdjuster: LenientOutreachRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientOutreachRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient outreach rule steps in order and keeps a trace of each.
    final class LenientOutreachRuleEngine {
        var steps: [any LenientOutreachRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOutreachRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientOutreachRule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientOutreachRuleModifier = steps[index]
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

        func evaluateAll(_ items: [LenientOutreachRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientOutreachRuleEngine() -> LenientOutreachRuleEngine {
        return LenientOutreachRuleEngine(
            steps: [
                CapLenientOutreachRuleAdjuster(cap: 42350.0),
                LenientOutreachRulePriorityOffsetAdjuster(weight: 1.11),
                NameLenientOutreachRuleAdjuster(factors: ["north": 0.87, "east": 0.83, "online": 0.84]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 67281.5
        )
    }
}
