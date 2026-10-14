import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network batch calculation.
    protocol NetworkBatchFactor {
        func describe() -> String
        func adjust(_ item: NetworkBatch, value: Double) -> Double
    }

    final class TieredNetworkBatchAdjuster: NetworkBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapNetworkBatchAdjuster: NetworkBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumNetworkBatchAdjuster: NetworkBatchFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelNetworkBatchAdjuster: NetworkBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentNetworkBatchAdjuster: NetworkBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkBatchWindowDaysOffsetAdjuster: NetworkBatchFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: NetworkBatch, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the network batch steps in order and keeps a trace of each.
    final class NetworkBatchEngine {
        var steps: [any NetworkBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkBatch) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkBatchFactor = steps[index]
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

        func evaluateAll(_ items: [NetworkBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkBatchEngine() -> NetworkBatchEngine {
        return NetworkBatchEngine(
            steps: [
                TieredNetworkBatchAdjuster(bounds: [2897.0, 4879.0], rates: [1.01, 1.12]),
                CapNetworkBatchAdjuster(cap: 48416.0),
                MinimumNetworkBatchAdjuster(minimum: 18.6),
                LabelNetworkBatchAdjuster(factors: ["central": 0.78, "retail": 1.03, "online": 0.78]),
                PercentNetworkBatchAdjuster(percent: 4.3),
                NetworkBatchWindowDaysOffsetAdjuster(weight: 1.66),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 30257.8
        )
    }
}
