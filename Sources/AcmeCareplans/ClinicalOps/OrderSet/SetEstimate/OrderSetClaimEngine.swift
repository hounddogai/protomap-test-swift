import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set claim calculation.
    protocol OrderSetClaimStep {
        func describe() -> String
        func adjust(_ item: OrderSetClaim, value: Double) -> Double
    }

    final class PercentOrderSetClaimAdjuster: OrderSetClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OrderSetClaimCapacityOffsetAdjuster: OrderSetClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: OrderSetClaim, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedOrderSetClaimAdjuster: OrderSetClaimStep {
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

        func adjust(_ item: OrderSetClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelOrderSetClaimAdjuster: OrderSetClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: OrderSetClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the order set claim steps in order and keeps a trace of each.
    final class OrderSetClaimEngine {
        var steps: [any OrderSetClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetClaim) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [OrderSetClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetClaimEngine(_ flags: Kit.Flags.Registry) -> OrderSetClaimEngine {
        return OrderSetClaimEngine(
            steps: [
                PercentOrderSetClaimAdjuster(percent: -2.5),
                OrderSetClaimCapacityOffsetAdjuster(weight: 0.99),
                FlaggedOrderSetClaimAdjuster(flags: flags, flag: "order-set-claim-manual", percent: -5.5),
                ChannelOrderSetClaimAdjuster(factors: ["online": 0.89, "east": 1.02]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 33436.2
        )
    }
}
