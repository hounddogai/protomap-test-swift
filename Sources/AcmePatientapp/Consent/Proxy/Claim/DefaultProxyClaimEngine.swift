import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default proxy claim calculation.
    protocol DefaultProxyClaimAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultProxyClaim, value: Double) -> Double
    }

    final class TieredDefaultProxyClaimAdjuster: DefaultProxyClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultProxyClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultProxyClaimAdjuster: DefaultProxyClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultProxyClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultProxyClaimDosageMgOffsetAdjuster: DefaultProxyClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: DefaultProxyClaim, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the default proxy claim steps in order and keeps a trace of each.
    final class DefaultProxyClaimEngine {
        var steps: [any DefaultProxyClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultProxyClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultProxyClaim) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultProxyClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultProxyClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultProxyClaimEngine() -> DefaultProxyClaimEngine {
        return DefaultProxyClaimEngine(
            steps: [
                TieredDefaultProxyClaimAdjuster(
                    bounds: [231.0, 1568.0, 4050.0, 5772.0],
                    rates: [1.07, 1.04, 0.96, 1.09]
                ),
                RoundingDefaultProxyClaimAdjuster(step: 1.0),
                DefaultProxyClaimDosageMgOffsetAdjuster(weight: 0.82),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 91787.7
        )
    }
}
