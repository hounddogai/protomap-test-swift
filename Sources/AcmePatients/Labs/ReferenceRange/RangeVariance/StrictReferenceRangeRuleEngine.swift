import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict reference range rule calculation.
    protocol StrictReferenceRangeRuleModifier {
        func describe() -> String
        func adjust(_ item: StrictReferenceRangeRule, value: Double) -> Double
    }

    final class StrictReferenceRangeRuleEndsAtOffsetAdjuster: StrictReferenceRangeRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: StrictReferenceRangeRule, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class NameStrictReferenceRangeRuleAdjuster: StrictReferenceRangeRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictReferenceRangeRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictReferenceRangeRuleAdjuster: StrictReferenceRangeRuleModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StrictReferenceRangeRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict reference range rule steps in order and keeps a trace of each.
    final class StrictReferenceRangeRuleEngine {
        var steps: [any StrictReferenceRangeRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReferenceRangeRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictReferenceRangeRule) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictReferenceRangeRuleModifier = steps[index]
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

        func evaluateAll(_ items: [StrictReferenceRangeRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictReferenceRangeRuleEngine(_ flags: Kit.Flags.Registry) -> StrictReferenceRangeRuleEngine {
        return StrictReferenceRangeRuleEngine(
            steps: [
                StrictReferenceRangeRuleEndsAtOffsetAdjuster(weight: 1.09),
                NameStrictReferenceRangeRuleAdjuster(factors: ["retail": 1.27, "west": 0.76]),
                FlaggedStrictReferenceRangeRuleAdjuster(
                    flags: flags,
                    flag: "strict-reference-range-rule-manual",
                    percent: 2.8
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 25388.8
        )
    }
}
