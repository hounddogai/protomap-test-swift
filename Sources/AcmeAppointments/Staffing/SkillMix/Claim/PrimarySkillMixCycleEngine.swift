import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary skill mix cycle calculation.
    protocol PrimarySkillMixCycleModifier {
        func describe() -> String
        func adjust(_ item: PrimarySkillMixCycle, value: Double) -> Double
    }

    final class TieredPrimarySkillMixCycleAdjuster: PrimarySkillMixCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySkillMixCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimarySkillMixCycleAdjuster: PrimarySkillMixCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimarySkillMixCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimarySkillMixCycleAdjuster: PrimarySkillMixCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimarySkillMixCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary skill mix cycle steps in order and keeps a trace of each.
    final class PrimarySkillMixCycleEngine {
        var steps: [any PrimarySkillMixCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySkillMixCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimarySkillMixCycle) -> Double {
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

        func evaluateAll(_ items: [PrimarySkillMixCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimarySkillMixCycleEngine() -> PrimarySkillMixCycleEngine {
        return PrimarySkillMixCycleEngine(
            steps: [
                TieredPrimarySkillMixCycleAdjuster(bounds: [6227.0, 9572.0], rates: [1.09, 0.91]),
                MinimumPrimarySkillMixCycleAdjuster(minimum: 34.0),
                CapPrimarySkillMixCycleAdjuster(cap: 20210.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 69399.8
        )
    }
}
