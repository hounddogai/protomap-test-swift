import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default skill mix score calculation.
    protocol DefaultSkillMixScoreAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultSkillMixScore, value: Double) -> Double
    }

    final class TieredDefaultSkillMixScoreAdjuster: DefaultSkillMixScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSkillMixScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultSkillMixScoreAdjuster: DefaultSkillMixScoreAdjuster {
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

        func adjust(_ item: DefaultSkillMixScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultSkillMixScoreAdjuster: DefaultSkillMixScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultSkillMixScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultSkillMixScoreAdjuster: DefaultSkillMixScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultSkillMixScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default skill mix score steps in order and keeps a trace of each.
    final class DefaultSkillMixScoreEngine {
        var steps: [any DefaultSkillMixScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSkillMixScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultSkillMixScore) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [DefaultSkillMixScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultSkillMixScoreEngine(_ flags: Kit.Flags.Registry) -> DefaultSkillMixScoreEngine {
        return DefaultSkillMixScoreEngine(
            steps: [
                TieredDefaultSkillMixScoreAdjuster(
                    bounds: [496.0, 1270.0, 2596.0, 6276.0],
                    rates: [0.84, 1.03, 1.15, 0.86]
                ),
                FlaggedDefaultSkillMixScoreAdjuster(
                    flags: flags,
                    flag: "default-skill-mix-score-tiered",
                    percent: -5.4
                ),
                CapDefaultSkillMixScoreAdjuster(cap: 4271.0),
                RoundingDefaultSkillMixScoreAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 30622.7
        )
    }
}
