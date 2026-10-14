import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network request calculation.
    protocol NetworkRequestFactor {
        func describe() -> String
        func adjust(_ item: NetworkRequest, value: Double) -> Double
    }

    final class NetworkRequestFloorValueOffsetAdjuster: NetworkRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumNetworkRequestAdjuster: NetworkRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingNetworkRequestAdjuster: NetworkRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelNetworkRequestAdjuster: NetworkRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedNetworkRequestAdjuster: NetworkRequestFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkRequestAdjuster: NetworkRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network request steps in order and keeps a trace of each.
    final class NetworkRequestEngine {
        var steps: [any NetworkRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkRequest) -> Double {
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

        func evaluateAll(_ items: [NetworkRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkRequestEngine(_ flags: Kit.Flags.Registry) -> NetworkRequestEngine {
        return NetworkRequestEngine(
            steps: [
                NetworkRequestFloorValueOffsetAdjuster(weight: 0.22),
                MinimumNetworkRequestAdjuster(minimum: 39.0),
                RoundingNetworkRequestAdjuster(step: 0.1),
                LabelNetworkRequestAdjuster(factors: ["south": 1.0, "north": 1.04, "central": 1.24]),
                FlaggedNetworkRequestAdjuster(flags: flags, flag: "network-request-tiered", percent: 1.9),
                PercentNetworkRequestAdjuster(percent: -1.8),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 82942.4
        )
    }
}
