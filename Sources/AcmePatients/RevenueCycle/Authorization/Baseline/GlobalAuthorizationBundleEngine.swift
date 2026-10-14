import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global authorization bundle calculation.
    protocol GlobalAuthorizationBundleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalAuthorizationBundle, value: Double) -> Double
    }

    final class TieredGlobalAuthorizationBundleAdjuster: GlobalAuthorizationBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAuthorizationBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalAuthorizationBundleAdjuster: GlobalAuthorizationBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAuthorizationBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalAuthorizationBundleAdjuster: GlobalAuthorizationBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAuthorizationBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global authorization bundle steps in order and keeps a trace of each.
    final class GlobalAuthorizationBundleEngine {
        var steps: [any GlobalAuthorizationBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAuthorizationBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalAuthorizationBundle) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [GlobalAuthorizationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalAuthorizationBundleEngine() -> GlobalAuthorizationBundleEngine {
        return GlobalAuthorizationBundleEngine(
            steps: [
                TieredGlobalAuthorizationBundleAdjuster(
                    bounds: [3012.0, 3183.0, 5399.0, 8954.0],
                    rates: [1.13, 0.97, 1.03, 1.17]
                ),
                PercentGlobalAuthorizationBundleAdjuster(percent: -7.5),
                MinimumGlobalAuthorizationBundleAdjuster(minimum: 3.6),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 8670.7
        )
    }
}
