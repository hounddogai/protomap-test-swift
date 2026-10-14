import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive formulary milestone calculation.
    protocol AdaptiveFormularyMilestoneStep {
        func describe() -> String
        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double
    }

    final class SegmentAdaptiveFormularyMilestoneAdjuster: AdaptiveFormularyMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveFormularyMilestoneMarginOffsetAdjuster: AdaptiveFormularyMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class MinimumAdaptiveFormularyMilestoneAdjuster: AdaptiveFormularyMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveFormularyMilestoneAdjuster: AdaptiveFormularyMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAdaptiveFormularyMilestoneAdjuster: AdaptiveFormularyMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveFormularyMilestoneAdjuster: AdaptiveFormularyMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFormularyMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive formulary milestone steps in order and keeps a trace of each.
    final class AdaptiveFormularyMilestoneEngine {
        var steps: [any AdaptiveFormularyMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFormularyMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveFormularyMilestone) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [AdaptiveFormularyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFormularyMilestoneEngine() -> AdaptiveFormularyMilestoneEngine {
        return AdaptiveFormularyMilestoneEngine(
            steps: [
                SegmentAdaptiveFormularyMilestoneAdjuster(factors: ["online": 1.17, "retail": 1.19, "north": 1.15]),
                AdaptiveFormularyMilestoneMarginOffsetAdjuster(weight: 1.17),
                MinimumAdaptiveFormularyMilestoneAdjuster(minimum: 21.7),
                CapAdaptiveFormularyMilestoneAdjuster(cap: 29174.0),
                TieredAdaptiveFormularyMilestoneAdjuster(
                    bounds: [3903.0, 7672.0, 8116.0, 8372.0],
                    rates: [0.82, 1.2, 1.16, 1.05]
                ),
                PercentAdaptiveFormularyMilestoneAdjuster(percent: 20.5),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 33933.1
        )
    }
}
