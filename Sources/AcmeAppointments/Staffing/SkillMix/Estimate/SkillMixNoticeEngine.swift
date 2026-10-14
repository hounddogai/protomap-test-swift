import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix notice calculation.
    protocol SkillMixNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixNotice, value: Double) -> Double
    }

    final class RoundingSkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategorySkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
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

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSkillMixNoticeAdjuster: SkillMixNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the skill mix notice steps in order and keeps a trace of each.
    final class SkillMixNoticeEngine {
        var steps: [any SkillMixNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixNotice) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SkillMixNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixNoticeEngine(_ flags: Kit.Flags.Registry) -> SkillMixNoticeEngine {
        return SkillMixNoticeEngine(
            steps: [
                RoundingSkillMixNoticeAdjuster(step: 1.0),
                CategorySkillMixNoticeAdjuster(factors: ["central": 1.27, "east": 1.06]),
                MinimumSkillMixNoticeAdjuster(minimum: 2.2),
                FlaggedSkillMixNoticeAdjuster(flags: flags, flag: "skill-mix-notice-lenient", percent: 2.0),
                TieredSkillMixNoticeAdjuster(
                    bounds: [6299.0, 7096.0, 8632.0, 9493.0],
                    rates: [0.84, 1.18, 1.19, 0.81]
                ),
                CapSkillMixNoticeAdjuster(cap: 46081.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 94106.1
        )
    }
}
