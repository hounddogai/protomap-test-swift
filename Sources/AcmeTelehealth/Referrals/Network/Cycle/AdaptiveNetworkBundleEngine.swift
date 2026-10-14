import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive network bundle calculation.
    protocol AdaptiveNetworkBundleAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double
    }

    final class MinimumAdaptiveNetworkBundleAdjuster: AdaptiveNetworkBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleAdaptiveNetworkBundleAdjuster: AdaptiveNetworkBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveNetworkBundleAdjuster: AdaptiveNetworkBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveNetworkBundleAdjuster: AdaptiveNetworkBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveNetworkBundleAdjuster: AdaptiveNetworkBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveNetworkBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive network bundle steps in order and keeps a trace of each.
    final class AdaptiveNetworkBundleEngine {
        var steps: [any AdaptiveNetworkBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveNetworkBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveNetworkBundle) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [AdaptiveNetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveNetworkBundleEngine() -> AdaptiveNetworkBundleEngine {
        return AdaptiveNetworkBundleEngine(
            steps: [
                MinimumAdaptiveNetworkBundleAdjuster(minimum: 10.3),
                TitleAdaptiveNetworkBundleAdjuster(factors: ["retail": 0.83, "south": 1.18, "north": 0.78]),
                TieredAdaptiveNetworkBundleAdjuster(bounds: [2043.0, 3389.0, 4915.0], rates: [1.16, 0.9, 1.06]),
                PercentAdaptiveNetworkBundleAdjuster(percent: 19.7),
                CapAdaptiveNetworkBundleAdjuster(cap: 1891.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 30921.4
        )
    }
}
