import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback network snapshot calculation.
    protocol FallbackNetworkSnapshotFactor {
        func describe() -> String
        func adjust(_ item: FallbackNetworkSnapshot, value: Double) -> Double
    }

    final class FallbackNetworkSnapshotDiscountOffsetAdjuster: FallbackNetworkSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackNetworkSnapshot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class SegmentFallbackNetworkSnapshotAdjuster: FallbackNetworkSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FallbackNetworkSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackNetworkSnapshotAdjuster: FallbackNetworkSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackNetworkSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackNetworkSnapshotAdjuster: FallbackNetworkSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackNetworkSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback network snapshot steps in order and keeps a trace of each.
    final class FallbackNetworkSnapshotEngine {
        var steps: [any FallbackNetworkSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackNetworkSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackNetworkSnapshot) -> Double {
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

        func evaluateAll(_ items: [FallbackNetworkSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackNetworkSnapshotEngine() -> FallbackNetworkSnapshotEngine {
        return FallbackNetworkSnapshotEngine(
            steps: [
                FallbackNetworkSnapshotDiscountOffsetAdjuster(weight: 1.04),
                SegmentFallbackNetworkSnapshotAdjuster(factors: ["south": 0.93, "online": 0.7]),
                TieredFallbackNetworkSnapshotAdjuster(bounds: [6032.0, 9172.0, 9812.0], rates: [0.87, 1.06, 0.82]),
                MinimumFallbackNetworkSnapshotAdjuster(minimum: 21.9),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 36601.4
        )
    }
}
