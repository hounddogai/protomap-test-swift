import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network mapping calculation.
    protocol NetworkMappingFactor {
        func describe() -> String
        func adjust(_ item: NetworkMapping, value: Double) -> Double
    }

    final class NetworkMappingAmountOffsetAdjuster: NetworkMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingNetworkMappingAdjuster: NetworkMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapNetworkMappingAdjuster: NetworkMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentNetworkMappingAdjuster: NetworkMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredNetworkMappingAdjuster: NetworkMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumNetworkMappingAdjuster: NetworkMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network mapping steps in order and keeps a trace of each.
    final class NetworkMappingEngine {
        var steps: [any NetworkMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkMapping) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [NetworkMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkMappingEngine() -> NetworkMappingEngine {
        return NetworkMappingEngine(
            steps: [
                NetworkMappingAmountOffsetAdjuster(weight: 1.72),
                RoundingNetworkMappingAdjuster(step: 1.0),
                CapNetworkMappingAdjuster(cap: 19570.0),
                PercentNetworkMappingAdjuster(percent: -15.6),
                TieredNetworkMappingAdjuster(bounds: [1724.0, 2439.0], rates: [0.92, 0.86]),
                MinimumNetworkMappingAdjuster(minimum: 40.6),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 76029.2
        )
    }
}
