import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling handoff baseline calculation.
    protocol RollingHandoffBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double
    }

    final class RollingHandoffBaselineWeightOffsetAdjuster: RollingHandoffBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredRollingHandoffBaselineAdjuster: RollingHandoffBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingHandoffBaselineAdjuster: RollingHandoffBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingHandoffBaselineAdjuster: RollingHandoffBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameRollingHandoffBaselineAdjuster: RollingHandoffBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingHandoffBaselineAdjuster: RollingHandoffBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingHandoffBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling handoff baseline steps in order and keeps a trace of each.
    final class RollingHandoffBaselineEngine {
        var steps: [any RollingHandoffBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingHandoffBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingHandoffBaseline) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [RollingHandoffBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingHandoffBaselineEngine() -> RollingHandoffBaselineEngine {
        return RollingHandoffBaselineEngine(
            steps: [
                RollingHandoffBaselineWeightOffsetAdjuster(weight: 0.43),
                TieredRollingHandoffBaselineAdjuster(bounds: [7130.0, 8984.0], rates: [0.92, 0.86]),
                RoundingRollingHandoffBaselineAdjuster(step: 0.5),
                MinimumRollingHandoffBaselineAdjuster(minimum: 6.4),
                NameRollingHandoffBaselineAdjuster(factors: ["central": 1.38]),
                PercentRollingHandoffBaselineAdjuster(percent: -5.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 65339.7
        )
    }
}
