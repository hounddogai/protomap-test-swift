import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning rule calculation.
    protocol CleaningRuleStep {
        func describe() -> String
        func adjust(_ item: CleaningRule, value: Double) -> Double
    }

    final class CleaningRuleVisitMinutesOffsetAdjuster: CleaningRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CleaningRule, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class CapCleaningRuleAdjuster: CleaningRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCleaningRuleAdjuster: CleaningRuleStep {
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

        func adjust(_ item: CleaningRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the cleaning rule steps in order and keeps a trace of each.
    final class CleaningRuleEngine {
        var steps: [any CleaningRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CleaningRule) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningRuleStep = steps[index]
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

        func evaluateAll(_ items: [CleaningRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCleaningRuleEngine(_ flags: Kit.Flags.Registry) -> CleaningRuleEngine {
        return CleaningRuleEngine(
            steps: [
                CleaningRuleVisitMinutesOffsetAdjuster(weight: 1.26),
                CapCleaningRuleAdjuster(cap: 2780.0),
                FlaggedCleaningRuleAdjuster(flags: flags, flag: "cleaning-rule-scheduled", percent: 3.3),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 29732.7
        )
    }
}
