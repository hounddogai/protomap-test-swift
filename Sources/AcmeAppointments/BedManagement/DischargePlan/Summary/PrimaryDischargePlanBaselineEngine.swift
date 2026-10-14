import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary discharge plan baseline calculation.
    protocol PrimaryDischargePlanBaselineModifier {
        func describe() -> String
        func adjust(_ item: PrimaryDischargePlanBaseline, value: Double) -> Double
    }

    final class TieredPrimaryDischargePlanBaselineAdjuster: PrimaryDischargePlanBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryDischargePlanBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitlePrimaryDischargePlanBaselineAdjuster: PrimaryDischargePlanBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryDischargePlanBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryDischargePlanBaselineAdjuster: PrimaryDischargePlanBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryDischargePlanBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryDischargePlanBaselineAdjuster: PrimaryDischargePlanBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDischargePlanBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary discharge plan baseline steps in order and keeps a trace of each.
    final class PrimaryDischargePlanBaselineEngine {
        var steps: [any PrimaryDischargePlanBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDischargePlanBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryDischargePlanBaseline) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryDischargePlanBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryDischargePlanBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryDischargePlanBaselineEngine() -> PrimaryDischargePlanBaselineEngine {
        return PrimaryDischargePlanBaselineEngine(
            steps: [
                TieredPrimaryDischargePlanBaselineAdjuster(
                    bounds: [1868.0, 6464.0, 6651.0, 6778.0],
                    rates: [1.05, 0.99, 0.96, 1.19]
                ),
                TitlePrimaryDischargePlanBaselineAdjuster(factors: ["west": 0.9]),
                PercentPrimaryDischargePlanBaselineAdjuster(percent: 14.3),
                RoundingPrimaryDischargePlanBaselineAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 73934.9
        )
    }
}
