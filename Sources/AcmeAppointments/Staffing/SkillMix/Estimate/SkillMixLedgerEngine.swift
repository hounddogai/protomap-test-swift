import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix ledger calculation.
    protocol SkillMixLedgerStep {
        func describe() -> String
        func adjust(_ item: SkillMixLedger, value: Double) -> Double
    }

    final class LabelSkillMixLedgerAdjuster: SkillMixLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SkillMixLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSkillMixLedgerAdjuster: SkillMixLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSkillMixLedgerAdjuster: SkillMixLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSkillMixLedgerAdjuster: SkillMixLedgerStep {
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

        func adjust(_ item: SkillMixLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the skill mix ledger steps in order and keeps a trace of each.
    final class SkillMixLedgerEngine {
        var steps: [any SkillMixLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixLedger) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixLedgerStep = steps[index]
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

        func evaluateAll(_ items: [SkillMixLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixLedgerEngine(_ flags: Kit.Flags.Registry) -> SkillMixLedgerEngine {
        return SkillMixLedgerEngine(
            steps: [
                LabelSkillMixLedgerAdjuster(factors: ["east": 1.31]),
                MinimumSkillMixLedgerAdjuster(minimum: 26.6),
                PercentSkillMixLedgerAdjuster(percent: -10.3),
                FlaggedSkillMixLedgerAdjuster(flags: flags, flag: "skill-mix-ledger-strict", percent: -2.1),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 39141.3
        )
    }
}
