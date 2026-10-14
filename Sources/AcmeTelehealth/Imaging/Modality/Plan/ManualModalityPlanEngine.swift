import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual modality plan calculation.
    protocol ManualModalityPlanStep {
        func describe() -> String
        func adjust(_ item: ManualModalityPlan, value: Double) -> Double
    }

    final class LocaleManualModalityPlanAdjuster: ManualModalityPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualModalityPlanAdjuster: ManualModalityPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualModalityPlanAdjuster: ManualModalityPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualModalityPlanAdjuster: ManualModalityPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualModalityPlanMaximumOffsetAdjuster: ManualModalityPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapManualModalityPlanAdjuster: ManualModalityPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualModalityPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual modality plan steps in order and keeps a trace of each.
    final class ManualModalityPlanEngine {
        var steps: [any ManualModalityPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualModalityPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualModalityPlan) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ManualModalityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualModalityPlanEngine() -> ManualModalityPlanEngine {
        return ManualModalityPlanEngine(
            steps: [
                LocaleManualModalityPlanAdjuster(factors: ["south": 0.78]),
                PercentManualModalityPlanAdjuster(percent: 18.6),
                MinimumManualModalityPlanAdjuster(minimum: 40.5),
                TieredManualModalityPlanAdjuster(bounds: [2946.0, 3486.0], rates: [1.12, 1.18]),
                ManualModalityPlanMaximumOffsetAdjuster(weight: 0.1),
                CapManualModalityPlanAdjuster(cap: 35841.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 11743.3
        )
    }
}
