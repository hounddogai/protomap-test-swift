import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix request calculation.
    protocol SkillMixRequestAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixRequest, value: Double) -> Double
    }

    final class RoundingSkillMixRequestAdjuster: SkillMixRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSkillMixRequestAdjuster: SkillMixRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSkillMixRequestAdjuster: SkillMixRequestAdjuster {
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

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSkillMixRequestAdjuster: SkillMixRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SkillMixRequestMaximumOffsetAdjuster: SkillMixRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class WardSkillMixRequestAdjuster: SkillMixRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: SkillMixRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the skill mix request steps in order and keeps a trace of each.
    final class SkillMixRequestEngine {
        var steps: [any SkillMixRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SkillMixRequest) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [SkillMixRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSkillMixRequestEngine(_ flags: Kit.Flags.Registry) -> SkillMixRequestEngine {
        return SkillMixRequestEngine(
            steps: [
                RoundingSkillMixRequestAdjuster(step: 0.1),
                CapSkillMixRequestAdjuster(cap: 22211.0),
                FlaggedSkillMixRequestAdjuster(flags: flags, flag: "skill-mix-request-adaptive", percent: 2.8),
                MinimumSkillMixRequestAdjuster(minimum: 2.2),
                SkillMixRequestMaximumOffsetAdjuster(weight: 0.43),
                WardSkillMixRequestAdjuster(factors: ["west": 1.27, "south": 0.83]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 52092.6
        )
    }
}
