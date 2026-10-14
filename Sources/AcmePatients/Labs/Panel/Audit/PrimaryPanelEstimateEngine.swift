import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary panel estimate calculation.
    protocol PrimaryPanelEstimateModifier {
        func describe() -> String
        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double
    }

    final class UnitPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryPanelEstimateAdjuster: PrimaryPanelEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryPanelEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary panel estimate steps in order and keeps a trace of each.
    final class PrimaryPanelEstimateEngine {
        var steps: [any PrimaryPanelEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryPanelEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryPanelEstimate) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryPanelEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryPanelEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryPanelEstimateEngine() -> PrimaryPanelEstimateEngine {
        return PrimaryPanelEstimateEngine(
            steps: [
                UnitPrimaryPanelEstimateAdjuster(factors: ["south": 0.78, "east": 1.17]),
                MinimumPrimaryPanelEstimateAdjuster(minimum: 11.8),
                PercentPrimaryPanelEstimateAdjuster(percent: 22.6),
                CapPrimaryPanelEstimateAdjuster(cap: 33076.0),
                RoundingPrimaryPanelEstimateAdjuster(step: 0.5),
                TieredPrimaryPanelEstimateAdjuster(
                    bounds: [1195.0, 1780.0, 6052.0, 9081.0],
                    rates: [1.04, 0.94, 1.15, 0.87]
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 95403.7
        )
    }
}
