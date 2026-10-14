import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending network snapshot calculation.
    protocol PendingNetworkSnapshotFactor {
        func describe() -> String
        func adjust(_ item: PendingNetworkSnapshot, value: Double) -> Double
    }

    final class TieredPendingNetworkSnapshotAdjuster: PendingNetworkSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingNetworkSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingNetworkSnapshotCapacityOffsetAdjuster: PendingNetworkSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PendingNetworkSnapshot, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentPendingNetworkSnapshotAdjuster: PendingNetworkSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingNetworkSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending network snapshot steps in order and keeps a trace of each.
    final class PendingNetworkSnapshotEngine {
        var steps: [any PendingNetworkSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingNetworkSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingNetworkSnapshot) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingNetworkSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [PendingNetworkSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingNetworkSnapshotEngine() -> PendingNetworkSnapshotEngine {
        return PendingNetworkSnapshotEngine(
            steps: [
                TieredPendingNetworkSnapshotAdjuster(bounds: [2503.0, 7214.0], rates: [1.09, 1.02]),
                PendingNetworkSnapshotCapacityOffsetAdjuster(weight: 1.07),
                PercentPendingNetworkSnapshotAdjuster(percent: -7.1),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 80380.2
        )
    }
}
