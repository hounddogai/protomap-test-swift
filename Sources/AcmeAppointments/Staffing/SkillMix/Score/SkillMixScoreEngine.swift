import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix score calculation.
    protocol SkillMixScoreStep {
        func describe() -> String
        func adjust(_ item: SkillMixScore, value: Double) -> Double
    }

    final class FlaggedSkillMixScoreAdjuster: SkillMixScoreStep {
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

        func adjust(_ item: SkillMixScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSkillMixScoreAdjuster: SkillMixScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSkillMixScoreAdjuster: SkillMixScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSkillMixScoreAdjuster: SkillMixScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the skill mix score steps in order and keeps a trace of each.
    final class SkillMixScoreEngine {
        var steps: [any SkillMixScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixScore) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [SkillMixScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixScoreEngine(_ flags: Kit.Flags.Registry) -> SkillMixScoreEngine {
        return SkillMixScoreEngine(
            steps: [
                FlaggedSkillMixScoreAdjuster(flags: flags, flag: "skill-mix-score-lenient", percent: -9.6),
                PercentSkillMixScoreAdjuster(percent: 11.8),
                TieredSkillMixScoreAdjuster(bounds: [1127.0, 2762.0, 9917.0], rates: [0.99, 0.97, 1.13]),
                CapSkillMixScoreAdjuster(cap: 14386.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 67996.5
        )
    }
}
