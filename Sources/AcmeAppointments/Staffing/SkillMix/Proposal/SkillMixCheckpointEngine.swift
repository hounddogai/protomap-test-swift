import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix checkpoint calculation.
    protocol SkillMixCheckpointModifier {
        func describe() -> String
        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double
    }

    final class CapSkillMixCheckpointAdjuster: SkillMixCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSkillMixCheckpointAdjuster: SkillMixCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SkillMixCheckpointCopayOffsetAdjuster: SkillMixCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class ChannelSkillMixCheckpointAdjuster: SkillMixCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSkillMixCheckpointAdjuster: SkillMixCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the skill mix checkpoint steps in order and keeps a trace of each.
    final class SkillMixCheckpointEngine {
        var steps: [any SkillMixCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixCheckpoint) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [SkillMixCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixCheckpointEngine() -> SkillMixCheckpointEngine {
        return SkillMixCheckpointEngine(
            steps: [
                CapSkillMixCheckpointAdjuster(cap: 35947.0),
                RoundingSkillMixCheckpointAdjuster(step: 0.25),
                SkillMixCheckpointCopayOffsetAdjuster(weight: 1.76),
                ChannelSkillMixCheckpointAdjuster(factors: ["west": 1.27, "retail": 1.04, "central": 1.04]),
                TieredSkillMixCheckpointAdjuster(bounds: [915.0, 2686.0], rates: [1.1, 0.95]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 94752.3
        )
    }
}
