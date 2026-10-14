import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling discharge plan summary calculation.
    protocol RollingDischargePlanSummaryModifier {
        func describe() -> String
        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double
    }

    final class RoundingRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingDischargePlanSummaryAdjuster: RollingDischargePlanSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDischargePlanSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling discharge plan summary steps in order and keeps a trace of each.
    final class RollingDischargePlanSummaryEngine {
        var steps: [any RollingDischargePlanSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDischargePlanSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingDischargePlanSummary) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RollingDischargePlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingDischargePlanSummaryEngine() -> RollingDischargePlanSummaryEngine {
        return RollingDischargePlanSummaryEngine(
            steps: [
                RoundingRollingDischargePlanSummaryAdjuster(step: 0.05),
                PercentRollingDischargePlanSummaryAdjuster(percent: -23.4),
                TitleRollingDischargePlanSummaryAdjuster(factors: ["south": 1.35]),
                CapRollingDischargePlanSummaryAdjuster(cap: 44763.0),
                MinimumRollingDischargePlanSummaryAdjuster(minimum: 6.4),
                TieredRollingDischargePlanSummaryAdjuster(
                    bounds: [3203.0, 3478.0, 8196.0, 8840.0],
                    rates: [0.84, 0.87, 0.9, 0.93]
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 77029.1
        )
    }
}
