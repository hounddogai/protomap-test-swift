import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix segment calculation.
    protocol SkillMixSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixSegment, value: Double) -> Double
    }

    final class CapSkillMixSegmentAdjuster: SkillMixSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SkillMixSegmentCopayOffsetAdjuster: SkillMixSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SkillMixSegment, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class SegmentSkillMixSegmentAdjuster: SkillMixSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SkillMixSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the skill mix segment steps in order and keeps a trace of each.
    final class SkillMixSegmentEngine {
        var steps: [any SkillMixSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixSegment) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [SkillMixSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixSegmentEngine() -> SkillMixSegmentEngine {
        return SkillMixSegmentEngine(
            steps: [
                CapSkillMixSegmentAdjuster(cap: 588.0),
                SkillMixSegmentCopayOffsetAdjuster(weight: 1.54),
                SegmentSkillMixSegmentAdjuster(factors: ["north": 0.73, "online": 0.74]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 76671.1
        )
    }
}
