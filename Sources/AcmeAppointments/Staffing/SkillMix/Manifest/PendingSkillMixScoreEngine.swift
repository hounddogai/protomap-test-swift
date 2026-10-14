import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending skill mix score calculation.
    protocol PendingSkillMixScoreAdjuster {
        func describe() -> String
        func adjust(_ item: PendingSkillMixScore, value: Double) -> Double
    }

    final class PendingSkillMixScoreCapacityOffsetAdjuster: PendingSkillMixScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PendingSkillMixScore, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingPendingSkillMixScoreAdjuster: PendingSkillMixScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingSkillMixScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingSkillMixScoreAdjuster: PendingSkillMixScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingSkillMixScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending skill mix score steps in order and keeps a trace of each.
    final class PendingSkillMixScoreEngine {
        var steps: [any PendingSkillMixScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSkillMixScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingSkillMixScore) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [PendingSkillMixScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingSkillMixScoreEngine() -> PendingSkillMixScoreEngine {
        return PendingSkillMixScoreEngine(
            steps: [
                PendingSkillMixScoreCapacityOffsetAdjuster(weight: 0.56),
                RoundingPendingSkillMixScoreAdjuster(step: 0.25),
                PercentPendingSkillMixScoreAdjuster(percent: 6.4),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 55951.9
        )
    }
}
