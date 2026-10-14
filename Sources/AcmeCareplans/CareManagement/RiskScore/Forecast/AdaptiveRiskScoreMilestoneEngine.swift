import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive risk score milestone calculation.
    protocol AdaptiveRiskScoreMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double
    }

    final class AdaptiveRiskScoreMilestoneSequenceOffsetAdjuster: AdaptiveRiskScoreMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredAdaptiveRiskScoreMilestoneAdjuster: AdaptiveRiskScoreMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveRiskScoreMilestoneAdjuster: AdaptiveRiskScoreMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryAdaptiveRiskScoreMilestoneAdjuster: AdaptiveRiskScoreMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAdaptiveRiskScoreMilestoneAdjuster: AdaptiveRiskScoreMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRiskScoreMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive risk score milestone steps in order and keeps a trace of each.
    final class AdaptiveRiskScoreMilestoneEngine {
        var steps: [any AdaptiveRiskScoreMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRiskScoreMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveRiskScoreMilestone) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRiskScoreMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRiskScoreMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRiskScoreMilestoneEngine() -> AdaptiveRiskScoreMilestoneEngine {
        return AdaptiveRiskScoreMilestoneEngine(
            steps: [
                AdaptiveRiskScoreMilestoneSequenceOffsetAdjuster(weight: 0.09),
                TieredAdaptiveRiskScoreMilestoneAdjuster(bounds: [3652.0, 8046.0], rates: [1.05, 0.88]),
                PercentAdaptiveRiskScoreMilestoneAdjuster(percent: -24.3),
                CountryAdaptiveRiskScoreMilestoneAdjuster(factors: ["central": 0.7]),
                MinimumAdaptiveRiskScoreMilestoneAdjuster(minimum: 20.4),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 29135.3
        )
    }
}
