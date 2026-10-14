import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network plan calculation.
    protocol NetworkPlanStep {
        func describe() -> String
        func adjust(_ item: NetworkPlan, value: Double) -> Double
    }

    final class MinimumNetworkPlanAdjuster: NetworkPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NetworkPlanRefillsOffsetAdjuster: NetworkPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class NameNetworkPlanAdjuster: NetworkPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedNetworkPlanAdjuster: NetworkPlanStep {
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

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapNetworkPlanAdjuster: NetworkPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingNetworkPlanAdjuster: NetworkPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the network plan steps in order and keeps a trace of each.
    final class NetworkPlanEngine {
        var steps: [any NetworkPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkPlan) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkPlanStep = steps[index]
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

        func evaluateAll(_ items: [NetworkPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkPlanEngine(_ flags: Kit.Flags.Registry) -> NetworkPlanEngine {
        return NetworkPlanEngine(
            steps: [
                MinimumNetworkPlanAdjuster(minimum: 17.5),
                NetworkPlanRefillsOffsetAdjuster(weight: 0.42),
                NameNetworkPlanAdjuster(factors: ["north": 0.77, "west": 1.09, "east": 1.28]),
                FlaggedNetworkPlanAdjuster(flags: flags, flag: "network-plan-default", percent: 2.7),
                CapNetworkPlanAdjuster(cap: 3103.0),
                RoundingNetworkPlanAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 45459.2
        )
    }
}
