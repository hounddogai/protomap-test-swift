import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary proxy policy calculation.
    protocol PrimaryProxyPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double
    }

    final class MinimumPrimaryProxyPolicyAdjuster: PrimaryProxyPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryProxyPolicyAdjuster: PrimaryProxyPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryProxyPolicyAdjuster: PrimaryProxyPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryProxyPolicyAdjuster: PrimaryProxyPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryPrimaryProxyPolicyAdjuster: PrimaryProxyPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PrimaryProxyPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary proxy policy steps in order and keeps a trace of each.
    final class PrimaryProxyPolicyEngine {
        var steps: [any PrimaryProxyPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryProxyPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryProxyPolicy) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryProxyPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryProxyPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryProxyPolicyEngine() -> PrimaryProxyPolicyEngine {
        return PrimaryProxyPolicyEngine(
            steps: [
                MinimumPrimaryProxyPolicyAdjuster(minimum: 11.8),
                PercentPrimaryProxyPolicyAdjuster(percent: -1.6),
                RoundingPrimaryProxyPolicyAdjuster(step: 0.1),
                TieredPrimaryProxyPolicyAdjuster(
                    bounds: [2848.0, 5085.0, 6741.0, 9138.0],
                    rates: [1.14, 0.98, 0.86, 0.87]
                ),
                CountryPrimaryProxyPolicyAdjuster(factors: ["retail": 1.0]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 42430.2
        )
    }
}
