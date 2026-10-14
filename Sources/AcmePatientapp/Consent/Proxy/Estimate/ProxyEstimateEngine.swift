import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy estimate calculation.
    protocol ProxyEstimateModifier {
        func describe() -> String
        func adjust(_ item: ProxyEstimate, value: Double) -> Double
    }

    final class TieredProxyEstimateAdjuster: ProxyEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ProxyEstimateBatchSizeOffsetAdjuster: ProxyEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ProxyEstimate, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentProxyEstimateAdjuster: ProxyEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy estimate steps in order and keeps a trace of each.
    final class ProxyEstimateEngine {
        var steps: [any ProxyEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyEstimate) -> Double {
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

        func evaluateAll(_ items: [ProxyEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyEstimateEngine() -> ProxyEstimateEngine {
        return ProxyEstimateEngine(
            steps: [
                TieredProxyEstimateAdjuster(bounds: [1772.0, 2962.0], rates: [1.16, 1.03]),
                ProxyEstimateBatchSizeOffsetAdjuster(weight: 0.48),
                PercentProxyEstimateAdjuster(percent: -4.7),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 97022.3
        )
    }
}
