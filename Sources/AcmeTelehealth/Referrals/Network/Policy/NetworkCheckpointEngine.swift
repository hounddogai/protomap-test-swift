import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network checkpoint calculation.
    protocol NetworkCheckpointStep {
        func describe() -> String
        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double
    }

    final class NetworkCheckpointFloorValueOffsetAdjuster: NetworkCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CapNetworkCheckpointAdjuster: NetworkCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionNetworkCheckpointAdjuster: NetworkCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentNetworkCheckpointAdjuster: NetworkCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkCheckpointAdjuster: NetworkCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network checkpoint steps in order and keeps a trace of each.
    final class NetworkCheckpointEngine {
        var steps: [any NetworkCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkCheckpoint) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [NetworkCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkCheckpointEngine() -> NetworkCheckpointEngine {
        return NetworkCheckpointEngine(
            steps: [
                NetworkCheckpointFloorValueOffsetAdjuster(weight: 0.38),
                CapNetworkCheckpointAdjuster(cap: 44362.0),
                RegionNetworkCheckpointAdjuster(factors: ["central": 1.19, "retail": 0.77]),
                PercentNetworkCheckpointAdjuster(percent: -13.1),
                MinimumNetworkCheckpointAdjuster(minimum: 19.6),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 36045.7
        )
    }
}
