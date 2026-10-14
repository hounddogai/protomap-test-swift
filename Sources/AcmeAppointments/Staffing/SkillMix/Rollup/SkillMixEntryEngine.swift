import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix entry calculation.
    protocol SkillMixEntryFactor {
        func describe() -> String
        func adjust(_ item: SkillMixEntry, value: Double) -> Double
    }

    final class TieredSkillMixEntryAdjuster: SkillMixEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSkillMixEntryAdjuster: SkillMixEntryFactor {
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

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSkillMixEntryAdjuster: SkillMixEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSkillMixEntryAdjuster: SkillMixEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSkillMixEntryAdjuster: SkillMixEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SkillMixEntryMaximumOffsetAdjuster: SkillMixEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: SkillMixEntry, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the skill mix entry steps in order and keeps a trace of each.
    final class SkillMixEntryEngine {
        var steps: [any SkillMixEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixEntry) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixEntryFactor = steps[index]
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

        func evaluateAll(_ items: [SkillMixEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixEntryEngine(_ flags: Kit.Flags.Registry) -> SkillMixEntryEngine {
        return SkillMixEntryEngine(
            steps: [
                TieredSkillMixEntryAdjuster(bounds: [1921.0, 4093.0, 5057.0, 7815.0], rates: [0.86, 1.12, 1.03, 1.19]),
                FlaggedSkillMixEntryAdjuster(flags: flags, flag: "skill-mix-entry-primary", percent: -9.7),
                MinimumSkillMixEntryAdjuster(minimum: 12.6),
                RoundingSkillMixEntryAdjuster(step: 0.5),
                CapSkillMixEntryAdjuster(cap: 37097.0),
                SkillMixEntryMaximumOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 25460.0
        )
    }
}
