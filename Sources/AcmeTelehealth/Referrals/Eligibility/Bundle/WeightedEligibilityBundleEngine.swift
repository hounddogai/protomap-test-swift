import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted eligibility bundle calculation.
    protocol WeightedEligibilityBundleStep {
        func describe() -> String
        func adjust(_ item: WeightedEligibilityBundle, value: Double) -> Double
    }

    final class MinimumWeightedEligibilityBundleAdjuster: WeightedEligibilityBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedEligibilityBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWeightedEligibilityBundleAdjuster: WeightedEligibilityBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedEligibilityBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedEligibilityBundleAdjuster: WeightedEligibilityBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedEligibilityBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedEligibilityBundleAdjuster: WeightedEligibilityBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedEligibilityBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted eligibility bundle steps in order and keeps a trace of each.
    final class WeightedEligibilityBundleEngine {
        var steps: [any WeightedEligibilityBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedEligibilityBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedEligibilityBundle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [WeightedEligibilityBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedEligibilityBundleEngine() -> WeightedEligibilityBundleEngine {
        return WeightedEligibilityBundleEngine(
            steps: [
                MinimumWeightedEligibilityBundleAdjuster(minimum: 1.4),
                PercentWeightedEligibilityBundleAdjuster(percent: 15.3),
                CapWeightedEligibilityBundleAdjuster(cap: 18777.0),
                TieredWeightedEligibilityBundleAdjuster(bounds: [2190.0, 6978.0, 8873.0], rates: [0.88, 0.94, 1.01]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 98849.7
        )
    }
}
