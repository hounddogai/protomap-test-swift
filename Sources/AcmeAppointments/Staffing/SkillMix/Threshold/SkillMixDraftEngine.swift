import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix draft calculation.
    protocol SkillMixDraftModifier {
        func describe() -> String
        func adjust(_ item: SkillMixDraft, value: Double) -> Double
    }

    final class SegmentSkillMixDraftAdjuster: SkillMixDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SkillMixDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSkillMixDraftAdjuster: SkillMixDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSkillMixDraftAdjuster: SkillMixDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SkillMixDraftQuantityOffsetAdjuster: SkillMixDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: SkillMixDraft, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the skill mix draft steps in order and keeps a trace of each.
    final class SkillMixDraftEngine {
        var steps: [any SkillMixDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixDraft) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [SkillMixDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixDraftEngine() -> SkillMixDraftEngine {
        return SkillMixDraftEngine(
            steps: [
                SegmentSkillMixDraftAdjuster(factors: ["north": 0.91]),
                RoundingSkillMixDraftAdjuster(step: 0.05),
                PercentSkillMixDraftAdjuster(percent: -2.6),
                SkillMixDraftQuantityOffsetAdjuster(weight: 1.66),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 89078.7
        )
    }
}
