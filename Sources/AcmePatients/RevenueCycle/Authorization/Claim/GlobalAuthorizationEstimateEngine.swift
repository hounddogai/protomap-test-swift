import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global authorization estimate calculation.
    protocol GlobalAuthorizationEstimateFactor {
        func describe() -> String
        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double
    }

    final class MinimumGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalAuthorizationEstimateAdjuster: GlobalAuthorizationEstimateFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: GlobalAuthorizationEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global authorization estimate steps in order and keeps a trace of each.
    final class GlobalAuthorizationEstimateEngine {
        var steps: [any GlobalAuthorizationEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAuthorizationEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalAuthorizationEstimate) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [GlobalAuthorizationEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalAuthorizationEstimateEngine(_ flags: Kit.Flags.Registry) -> GlobalAuthorizationEstimateEngine {
        return GlobalAuthorizationEstimateEngine(
            steps: [
                MinimumGlobalAuthorizationEstimateAdjuster(minimum: 9.2),
                PercentGlobalAuthorizationEstimateAdjuster(percent: -12.3),
                RegionGlobalAuthorizationEstimateAdjuster(factors: ["west": 1.25, "east": 1.37]),
                TieredGlobalAuthorizationEstimateAdjuster(
                    bounds: [204.0, 1341.0, 2603.0, 9058.0],
                    rates: [1.16, 0.92, 0.95, 0.87]
                ),
                CapGlobalAuthorizationEstimateAdjuster(cap: 8182.0),
                FlaggedGlobalAuthorizationEstimateAdjuster(
                    flags: flags,
                    flag: "global-authorization-estimate-pending",
                    percent: 1.5
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 3559.2
        )
    }
}
