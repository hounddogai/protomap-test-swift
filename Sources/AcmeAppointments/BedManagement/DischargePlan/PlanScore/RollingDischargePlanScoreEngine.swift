import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling discharge plan score calculation.
    protocol RollingDischargePlanScoreStep {
        func describe() -> String
        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double
    }

    final class RoundingRollingDischargePlanScoreAdjuster: RollingDischargePlanScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingDischargePlanScoreRefillsOffsetAdjuster: RollingDischargePlanScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TitleRollingDischargePlanScoreAdjuster: RollingDischargePlanScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingDischargePlanScoreAdjuster: RollingDischargePlanScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRollingDischargePlanScoreAdjuster: RollingDischargePlanScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingDischargePlanScoreAdjuster: RollingDischargePlanScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingDischargePlanScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling discharge plan score steps in order and keeps a trace of each.
    final class RollingDischargePlanScoreEngine {
        var steps: [any RollingDischargePlanScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDischargePlanScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingDischargePlanScore) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingDischargePlanScoreStep = steps[index]
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

        func evaluateAll(_ items: [RollingDischargePlanScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingDischargePlanScoreEngine() -> RollingDischargePlanScoreEngine {
        return RollingDischargePlanScoreEngine(
            steps: [
                RoundingRollingDischargePlanScoreAdjuster(step: 1.0),
                RollingDischargePlanScoreRefillsOffsetAdjuster(weight: 1.67),
                TitleRollingDischargePlanScoreAdjuster(factors: ["south": 1.28]),
                TieredRollingDischargePlanScoreAdjuster(
                    bounds: [1815.0, 2864.0, 6118.0, 7245.0],
                    rates: [1.17, 1.04, 1.14, 1.07]
                ),
                PercentRollingDischargePlanScoreAdjuster(percent: -6.0),
                CapRollingDischargePlanScoreAdjuster(cap: 29444.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 28055.7
        )
    }
}
