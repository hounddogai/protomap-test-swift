import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted discharge plan summary calculation.
    protocol WeightedDischargePlanSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double
    }

    final class CapWeightedDischargePlanSummaryAdjuster: WeightedDischargePlanSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameWeightedDischargePlanSummaryAdjuster: WeightedDischargePlanSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedDischargePlanSummaryAdjuster: WeightedDischargePlanSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedDischargePlanSummaryThresholdOffsetAdjuster: WeightedDischargePlanSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentWeightedDischargePlanSummaryAdjuster: WeightedDischargePlanSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedDischargePlanSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted discharge plan summary steps in order and keeps a trace of each.
    final class WeightedDischargePlanSummaryEngine {
        var steps: [any WeightedDischargePlanSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDischargePlanSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedDischargePlanSummary) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [WeightedDischargePlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedDischargePlanSummaryEngine() -> WeightedDischargePlanSummaryEngine {
        return WeightedDischargePlanSummaryEngine(
            steps: [
                CapWeightedDischargePlanSummaryAdjuster(cap: 10647.0),
                NameWeightedDischargePlanSummaryAdjuster(factors: ["east": 0.84]),
                TieredWeightedDischargePlanSummaryAdjuster(
                    bounds: [8366.0, 8497.0, 9863.0],
                    rates: [0.98, 0.96, 0.98]
                ),
                WeightedDischargePlanSummaryThresholdOffsetAdjuster(weight: 0.51),
                PercentWeightedDischargePlanSummaryAdjuster(percent: 18.1),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 39324.4
        )
    }
}
