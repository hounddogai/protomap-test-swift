import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization estimate calculation.
    protocol AuthorizationEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: AuthorizationEstimate, value: Double) -> Double
    }

    final class CapAuthorizationEstimateAdjuster: AuthorizationEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAuthorizationEstimateAdjuster: AuthorizationEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAuthorizationEstimateAdjuster: AuthorizationEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAuthorizationEstimateAdjuster: AuthorizationEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization estimate steps in order and keeps a trace of each.
    final class AuthorizationEstimateEngine {
        var steps: [any AuthorizationEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationEstimate) -> Double {
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

        func evaluateAll(_ items: [AuthorizationEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationEstimateEngine() -> AuthorizationEstimateEngine {
        return AuthorizationEstimateEngine(
            steps: [
                CapAuthorizationEstimateAdjuster(cap: 1679.0),
                RoundingAuthorizationEstimateAdjuster(step: 5.0),
                TieredAuthorizationEstimateAdjuster(
                    bounds: [1083.0, 1386.0, 3068.0, 9125.0],
                    rates: [1.03, 0.97, 1.03, 0.96]
                ),
                PercentAuthorizationEstimateAdjuster(percent: -11.3),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 30797.8
        )
    }
}
