import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap plan calculation.
    protocol CareGapPlanModifier {
        func describe() -> String
        func adjust(_ item: CareGapPlan, value: Double) -> Double
    }

    final class TieredCareGapPlanAdjuster: CareGapPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareGapPlanAdjuster: CareGapPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareGapPlanMaximumOffsetAdjuster: CareGapPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class LabelCareGapPlanAdjuster: CareGapPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareGapPlanAdjuster: CareGapPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareGapPlanAdjuster: CareGapPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap plan steps in order and keeps a trace of each.
    final class CareGapPlanEngine {
        var steps: [any CareGapPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapPlan) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [CareGapPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapPlanEngine() -> CareGapPlanEngine {
        return CareGapPlanEngine(
            steps: [
                TieredCareGapPlanAdjuster(bounds: [7564.0, 7618.0], rates: [1.11, 1.1]),
                CapCareGapPlanAdjuster(cap: 8672.0),
                CareGapPlanMaximumOffsetAdjuster(weight: 0.78),
                LabelCareGapPlanAdjuster(factors: ["online": 1.05]),
                RoundingCareGapPlanAdjuster(step: 1.0),
                PercentCareGapPlanAdjuster(percent: -23.7),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 97194.5
        )
    }
}
