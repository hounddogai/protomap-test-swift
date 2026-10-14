import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy slot calculation.
    protocol ProxySlotStep {
        func describe() -> String
        func adjust(_ item: ProxySlot, value: Double) -> Double
    }

    final class LabelProxySlotAdjuster: ProxySlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ProxySlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProxySlotAdjuster: ProxySlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProxySlotAdjuster: ProxySlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy slot steps in order and keeps a trace of each.
    final class ProxySlotEngine {
        var steps: [any ProxySlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxySlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxySlot) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxySlotStep = steps[index]
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

        func evaluateAll(_ items: [ProxySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxySlotEngine() -> ProxySlotEngine {
        return ProxySlotEngine(
            steps: [
                LabelProxySlotAdjuster(factors: ["central": 0.99, "west": 1.03]),
                TieredProxySlotAdjuster(bounds: [293.0, 9946.0], rates: [0.97, 1.07]),
                PercentProxySlotAdjuster(percent: -8.2),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 54273.9
        )
    }
}
