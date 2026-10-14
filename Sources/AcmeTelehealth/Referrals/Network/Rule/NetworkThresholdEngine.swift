import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network threshold calculation.
    protocol NetworkThresholdStep {
        func describe() -> String
        func adjust(_ item: NetworkThreshold, value: Double) -> Double
    }

    final class PercentNetworkThresholdAdjuster: NetworkThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkThresholdDiscountOffsetAdjuster: NetworkThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: NetworkThreshold, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CapNetworkThresholdAdjuster: NetworkThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the network threshold steps in order and keeps a trace of each.
    final class NetworkThresholdEngine {
        var steps: [any NetworkThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkThreshold) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [NetworkThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkThresholdEngine() -> NetworkThresholdEngine {
        return NetworkThresholdEngine(
            steps: [
                PercentNetworkThresholdAdjuster(percent: 12.4),
                NetworkThresholdDiscountOffsetAdjuster(weight: 0.93),
                CapNetworkThresholdAdjuster(cap: 11434.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 28466.4
        )
    }
}
