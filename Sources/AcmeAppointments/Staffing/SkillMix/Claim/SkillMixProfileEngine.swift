import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix profile calculation.
    protocol SkillMixProfileAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixProfile, value: Double) -> Double
    }

    final class PercentSkillMixProfileAdjuster: SkillMixProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SkillMixProfileVisitMinutesOffsetAdjuster: SkillMixProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: SkillMixProfile, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingSkillMixProfileAdjuster: SkillMixProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSkillMixProfileAdjuster: SkillMixProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the skill mix profile steps in order and keeps a trace of each.
    final class SkillMixProfileEngine {
        var steps: [any SkillMixProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixProfile) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [SkillMixProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixProfileEngine() -> SkillMixProfileEngine {
        return SkillMixProfileEngine(
            steps: [
                PercentSkillMixProfileAdjuster(percent: 17.1),
                SkillMixProfileVisitMinutesOffsetAdjuster(weight: 0.08),
                RoundingSkillMixProfileAdjuster(step: 0.5),
                MinimumSkillMixProfileAdjuster(minimum: 31.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 46929.0
        )
    }
}
