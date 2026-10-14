import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix audit calculation.
    protocol SkillMixAuditAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixAudit, value: Double) -> Double
    }

    final class RoundingSkillMixAuditAdjuster: SkillMixAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SkillMixAuditCopayOffsetAdjuster: SkillMixAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SkillMixAudit, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapSkillMixAuditAdjuster: SkillMixAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the skill mix audit steps in order and keeps a trace of each.
    final class SkillMixAuditEngine {
        var steps: [any SkillMixAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SkillMixAudit) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [SkillMixAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSkillMixAuditEngine() -> SkillMixAuditEngine {
        return SkillMixAuditEngine(
            steps: [
                RoundingSkillMixAuditAdjuster(step: 0.1),
                SkillMixAuditCopayOffsetAdjuster(weight: 1.12),
                CapSkillMixAuditAdjuster(cap: 44398.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 52136.2
        )
    }
}
