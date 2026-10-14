import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling skill mix manifest calculation.
    protocol RollingSkillMixManifestStep {
        func describe() -> String
        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double
    }

    final class WardRollingSkillMixManifestAdjuster: RollingSkillMixManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingSkillMixManifestSequenceOffsetAdjuster: RollingSkillMixManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingRollingSkillMixManifestAdjuster: RollingSkillMixManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingSkillMixManifestAdjuster: RollingSkillMixManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingSkillMixManifestAdjuster: RollingSkillMixManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingSkillMixManifestAdjuster: RollingSkillMixManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingSkillMixManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling skill mix manifest steps in order and keeps a trace of each.
    final class RollingSkillMixManifestEngine {
        var steps: [any RollingSkillMixManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSkillMixManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingSkillMixManifest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingSkillMixManifestStep = steps[index]
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

        func evaluateAll(_ items: [RollingSkillMixManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingSkillMixManifestEngine() -> RollingSkillMixManifestEngine {
        return RollingSkillMixManifestEngine(
            steps: [
                WardRollingSkillMixManifestAdjuster(factors: ["north": 1.35, "retail": 0.98, "online": 1.24]),
                RollingSkillMixManifestSequenceOffsetAdjuster(weight: 1.23),
                RoundingRollingSkillMixManifestAdjuster(step: 0.1),
                CapRollingSkillMixManifestAdjuster(cap: 41897.0),
                TieredRollingSkillMixManifestAdjuster(
                    bounds: [2304.0, 3576.0, 5876.0, 6058.0],
                    rates: [0.81, 1.03, 1.08, 1.03]
                ),
                MinimumRollingSkillMixManifestAdjuster(minimum: 9.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 92516.9
        )
    }
}
