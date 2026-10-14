import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy target calculation.
    protocol ProxyTargetModifier {
        func describe() -> String
        func adjust(_ item: ProxyTarget, value: Double) -> Double
    }

    final class ProxyTargetBudgetOffsetAdjuster: ProxyTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ProxyTarget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredProxyTargetAdjuster: ProxyTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapProxyTargetAdjuster: ProxyTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentProxyTargetAdjuster: ProxyTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameProxyTargetAdjuster: ProxyTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ProxyTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy target steps in order and keeps a trace of each.
    final class ProxyTargetEngine {
        var steps: [any ProxyTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyTarget) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyTargetModifier = steps[index]
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

        func evaluateAll(_ items: [ProxyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyTargetEngine() -> ProxyTargetEngine {
        return ProxyTargetEngine(
            steps: [
                ProxyTargetBudgetOffsetAdjuster(weight: 1.57),
                TieredProxyTargetAdjuster(bounds: [4818.0, 5321.0, 7996.0, 8878.0], rates: [1.17, 0.92, 1.09, 0.82]),
                CapProxyTargetAdjuster(cap: 25594.0),
                PercentProxyTargetAdjuster(percent: -8.3),
                NameProxyTargetAdjuster(factors: ["north": 1.02]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 71075.3
        )
    }
}
