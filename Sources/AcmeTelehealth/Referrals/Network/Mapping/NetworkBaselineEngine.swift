import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network baseline calculation.
    protocol NetworkBaselineFactor {
        func describe() -> String
        func adjust(_ item: NetworkBaseline, value: Double) -> Double
    }

    final class FlaggedNetworkBaselineAdjuster: NetworkBaselineFactor {
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

        func adjust(_ item: NetworkBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingNetworkBaselineAdjuster: NetworkBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitNetworkBaselineAdjuster: NetworkBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: NetworkBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumNetworkBaselineAdjuster: NetworkBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network baseline steps in order and keeps a trace of each.
    final class NetworkBaselineEngine {
        var steps: [any NetworkBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkBaseline) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [NetworkBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkBaselineEngine(_ flags: Kit.Flags.Registry) -> NetworkBaselineEngine {
        return NetworkBaselineEngine(
            steps: [
                FlaggedNetworkBaselineAdjuster(flags: flags, flag: "network-baseline-default", percent: -1.8),
                RoundingNetworkBaselineAdjuster(step: 0.25),
                UnitNetworkBaselineAdjuster(factors: ["north": 0.8, "online": 1.4, "retail": 1.07]),
                MinimumNetworkBaselineAdjuster(minimum: 40.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 10580.3
        )
    }
}
