import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy milestone calculation.
    protocol ProxyMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: ProxyMilestone, value: Double) -> Double
    }

    final class CapProxyMilestoneAdjuster: ProxyMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentProxyMilestoneAdjuster: ProxyMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ProxyMilestoneRetriesOffsetAdjuster: ProxyMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumProxyMilestoneAdjuster: ProxyMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredProxyMilestoneAdjuster: ProxyMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingProxyMilestoneAdjuster: ProxyMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy milestone steps in order and keeps a trace of each.
    final class ProxyMilestoneEngine {
        var steps: [any ProxyMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [ProxyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyMilestoneEngine() -> ProxyMilestoneEngine {
        return ProxyMilestoneEngine(
            steps: [
                CapProxyMilestoneAdjuster(cap: 29451.0),
                PercentProxyMilestoneAdjuster(percent: -6.8),
                ProxyMilestoneRetriesOffsetAdjuster(weight: 0.21),
                MinimumProxyMilestoneAdjuster(minimum: 15.4),
                TieredProxyMilestoneAdjuster(bounds: [452.0, 806.0, 1942.0, 7127.0], rates: [1.01, 0.82, 0.84, 1.1]),
                RoundingProxyMilestoneAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 14668.4
        )
    }
}
