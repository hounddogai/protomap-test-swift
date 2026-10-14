import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network score calculation.
    protocol NetworkScoreAdjuster {
        func describe() -> String
        func adjust(_ item: NetworkScore, value: Double) -> Double
    }

    final class FlaggedNetworkScoreAdjuster: NetworkScoreAdjuster {
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

        func adjust(_ item: NetworkScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityNetworkScoreAdjuster: NetworkScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: NetworkScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumNetworkScoreAdjuster: NetworkScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NetworkScoreLimitOffsetAdjuster: NetworkScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: NetworkScore, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the network score steps in order and keeps a trace of each.
    final class NetworkScoreEngine {
        var steps: [any NetworkScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkScore) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [NetworkScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkScoreEngine(_ flags: Kit.Flags.Registry) -> NetworkScoreEngine {
        return NetworkScoreEngine(
            steps: [
                FlaggedNetworkScoreAdjuster(flags: flags, flag: "network-score-batched", percent: -4.7),
                FacilityNetworkScoreAdjuster(factors: ["central": 0.82, "south": 1.3, "north": 0.96]),
                MinimumNetworkScoreAdjuster(minimum: 0.5),
                NetworkScoreLimitOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 80049.3
        )
    }
}
