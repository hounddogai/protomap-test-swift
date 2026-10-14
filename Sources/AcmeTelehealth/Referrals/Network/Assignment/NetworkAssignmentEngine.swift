import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network assignment calculation.
    protocol NetworkAssignmentFactor {
        func describe() -> String
        func adjust(_ item: NetworkAssignment, value: Double) -> Double
    }

    final class PercentNetworkAssignmentAdjuster: NetworkAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkAssignmentAdjuster: NetworkAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NetworkAssignmentRefillsOffsetAdjuster: NetworkAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredNetworkAssignmentAdjuster: NetworkAssignmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedNetworkAssignmentAdjuster: NetworkAssignmentFactor {
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

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapNetworkAssignmentAdjuster: NetworkAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the network assignment steps in order and keeps a trace of each.
    final class NetworkAssignmentEngine {
        var steps: [any NetworkAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkAssignment) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [NetworkAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkAssignmentEngine(_ flags: Kit.Flags.Registry) -> NetworkAssignmentEngine {
        return NetworkAssignmentEngine(
            steps: [
                PercentNetworkAssignmentAdjuster(percent: 4.3),
                MinimumNetworkAssignmentAdjuster(minimum: 44.6),
                NetworkAssignmentRefillsOffsetAdjuster(weight: 1.62),
                TieredNetworkAssignmentAdjuster(
                    bounds: [2059.0, 4155.0, 5038.0, 8858.0],
                    rates: [0.82, 0.9, 0.85, 1.0]
                ),
                FlaggedNetworkAssignmentAdjuster(flags: flags, flag: "network-assignment-tiered", percent: -2.5),
                CapNetworkAssignmentAdjuster(cap: 40569.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 57519.0
        )
    }
}
