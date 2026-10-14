import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network draft calculation.
    protocol NetworkDraftAdjuster {
        func describe() -> String
        func adjust(_ item: NetworkDraft, value: Double) -> Double
    }

    final class RegionNetworkDraftAdjuster: NetworkDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapNetworkDraftAdjuster: NetworkDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredNetworkDraftAdjuster: NetworkDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedNetworkDraftAdjuster: NetworkDraftAdjuster {
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

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkDraftAdjuster: NetworkDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkDraftSequenceOffsetAdjuster: NetworkDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: NetworkDraft, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the network draft steps in order and keeps a trace of each.
    final class NetworkDraftEngine {
        var steps: [any NetworkDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkDraft) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [NetworkDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkDraftEngine(_ flags: Kit.Flags.Registry) -> NetworkDraftEngine {
        return NetworkDraftEngine(
            steps: [
                RegionNetworkDraftAdjuster(factors: ["retail": 0.88, "north": 1.25, "south": 1.32]),
                CapNetworkDraftAdjuster(cap: 2540.0),
                TieredNetworkDraftAdjuster(bounds: [2969.0, 3970.0, 7584.0, 8609.0], rates: [0.89, 0.96, 1.11, 1.02]),
                FlaggedNetworkDraftAdjuster(flags: flags, flag: "network-draft-primary", percent: -8.2),
                PercentNetworkDraftAdjuster(percent: -13.5),
                NetworkDraftSequenceOffsetAdjuster(weight: 1.08),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 75258.5
        )
    }
}
