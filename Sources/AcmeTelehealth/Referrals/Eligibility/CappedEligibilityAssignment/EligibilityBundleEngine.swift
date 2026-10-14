import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility bundle calculation.
    protocol EligibilityBundleAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilityBundle, value: Double) -> Double
    }

    final class EligibilityBundleCostOffsetAdjuster: EligibilityBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: EligibilityBundle, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredEligibilityBundleAdjuster: EligibilityBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentEligibilityBundleAdjuster: EligibilityBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingEligibilityBundleAdjuster: EligibilityBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the eligibility bundle steps in order and keeps a trace of each.
    final class EligibilityBundleEngine {
        var steps: [any EligibilityBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityBundle) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [EligibilityBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityBundleEngine() -> EligibilityBundleEngine {
        return EligibilityBundleEngine(
            steps: [
                EligibilityBundleCostOffsetAdjuster(weight: 1.28),
                TieredEligibilityBundleAdjuster(bounds: [3488.0, 5519.0], rates: [0.95, 0.99]),
                PercentEligibilityBundleAdjuster(percent: 23.4),
                RoundingEligibilityBundleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 87872.6
        )
    }
}
