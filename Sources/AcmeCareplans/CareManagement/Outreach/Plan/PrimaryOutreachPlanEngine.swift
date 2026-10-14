import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary outreach plan calculation.
    protocol PrimaryOutreachPlanStep {
        func describe() -> String
        func adjust(_ item: PrimaryOutreachPlan, value: Double) -> Double
    }

    final class ChannelPrimaryOutreachPlanAdjuster: PrimaryOutreachPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryOutreachPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryOutreachPlanThresholdOffsetAdjuster: PrimaryOutreachPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: PrimaryOutreachPlan, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredPrimaryOutreachPlanAdjuster: PrimaryOutreachPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOutreachPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryOutreachPlanAdjuster: PrimaryOutreachPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOutreachPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary outreach plan steps in order and keeps a trace of each.
    final class PrimaryOutreachPlanEngine {
        var steps: [any PrimaryOutreachPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOutreachPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryOutreachPlan) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [PrimaryOutreachPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryOutreachPlanEngine() -> PrimaryOutreachPlanEngine {
        return PrimaryOutreachPlanEngine(
            steps: [
                ChannelPrimaryOutreachPlanAdjuster(factors: ["south": 0.75]),
                PrimaryOutreachPlanThresholdOffsetAdjuster(weight: 1.77),
                TieredPrimaryOutreachPlanAdjuster(bounds: [2171.0, 3087.0, 9820.0], rates: [0.95, 1.02, 1.11]),
                PercentPrimaryOutreachPlanAdjuster(percent: 21.7),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 74455.0
        )
    }
}
