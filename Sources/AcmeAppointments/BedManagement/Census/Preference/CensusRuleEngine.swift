import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census rule calculation.
    protocol CensusRuleStep {
        func describe() -> String
        func adjust(_ item: CensusRule, value: Double) -> Double
    }

    final class RoundingCensusRuleAdjuster: CensusRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCensusRuleAdjuster: CensusRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCensusRuleAdjuster: CensusRuleStep {
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

        func adjust(_ item: CensusRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census rule steps in order and keeps a trace of each.
    final class CensusRuleEngine {
        var steps: [any CensusRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusRule) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [CensusRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusRuleEngine(_ flags: Kit.Flags.Registry) -> CensusRuleEngine {
        return CensusRuleEngine(
            steps: [
                RoundingCensusRuleAdjuster(step: 0.05),
                MinimumCensusRuleAdjuster(minimum: 12.0),
                FlaggedCensusRuleAdjuster(flags: flags, flag: "census-rule-lenient", percent: -2.3),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 69390.5
        )
    }
}
