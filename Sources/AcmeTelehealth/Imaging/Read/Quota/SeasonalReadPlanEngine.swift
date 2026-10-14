import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal read plan calculation.
    protocol SeasonalReadPlanModifier {
        func describe() -> String
        func adjust(_ item: SeasonalReadPlan, value: Double) -> Double
    }

    final class CountrySeasonalReadPlanAdjuster: SeasonalReadPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: SeasonalReadPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalReadPlanAdjuster: SeasonalReadPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalReadPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalReadPlanAdjuster: SeasonalReadPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalReadPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal read plan steps in order and keeps a trace of each.
    final class SeasonalReadPlanEngine {
        var steps: [any SeasonalReadPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReadPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalReadPlan) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [SeasonalReadPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalReadPlanEngine() -> SeasonalReadPlanEngine {
        return SeasonalReadPlanEngine(
            steps: [
                CountrySeasonalReadPlanAdjuster(factors: ["south": 0.97]),
                PercentSeasonalReadPlanAdjuster(percent: 11.4),
                CapSeasonalReadPlanAdjuster(cap: 19797.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 42167.3
        )
    }
}
