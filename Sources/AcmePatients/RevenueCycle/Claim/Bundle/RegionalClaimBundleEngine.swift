import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional claim bundle calculation.
    protocol RegionalClaimBundleStep {
        func describe() -> String
        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double
    }

    final class RoundingRegionalClaimBundleAdjuster: RegionalClaimBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalClaimBundleRetriesOffsetAdjuster: RegionalClaimBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class CapRegionalClaimBundleAdjuster: RegionalClaimBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalClaimBundleAdjuster: RegionalClaimBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRegionalClaimBundleAdjuster: RegionalClaimBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalClaimBundleAdjuster: RegionalClaimBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalClaimBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional claim bundle steps in order and keeps a trace of each.
    final class RegionalClaimBundleEngine {
        var steps: [any RegionalClaimBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalClaimBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalClaimBundle) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [RegionalClaimBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalClaimBundleEngine() -> RegionalClaimBundleEngine {
        return RegionalClaimBundleEngine(
            steps: [
                RoundingRegionalClaimBundleAdjuster(step: 0.05),
                RegionalClaimBundleRetriesOffsetAdjuster(weight: 0.97),
                CapRegionalClaimBundleAdjuster(cap: 15066.0),
                PercentRegionalClaimBundleAdjuster(percent: 6.7),
                LabelRegionalClaimBundleAdjuster(factors: ["west": 1.22]),
                TieredRegionalClaimBundleAdjuster(bounds: [8645.0, 9845.0, 9920.0], rates: [0.9, 0.91, 1.12]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 3823.3
        )
    }
}
