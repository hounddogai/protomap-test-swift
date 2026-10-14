import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network agreement calculation.
    protocol NetworkAgreementStep {
        func describe() -> String
        func adjust(_ item: NetworkAgreement, value: Double) -> Double
    }

    final class RegionNetworkAgreementAdjuster: NetworkAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: NetworkAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredNetworkAgreementAdjuster: NetworkAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NetworkAgreementRateOffsetAdjuster: NetworkAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: NetworkAgreement, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedNetworkAgreementAdjuster: NetworkAgreementStep {
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

        func adjust(_ item: NetworkAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkAgreementAdjuster: NetworkAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network agreement steps in order and keeps a trace of each.
    final class NetworkAgreementEngine {
        var steps: [any NetworkAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkAgreement) -> Double {
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

        func evaluateAll(_ items: [NetworkAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkAgreementEngine(_ flags: Kit.Flags.Registry) -> NetworkAgreementEngine {
        return NetworkAgreementEngine(
            steps: [
                RegionNetworkAgreementAdjuster(factors: ["north": 0.91, "retail": 0.77, "west": 1.21]),
                TieredNetworkAgreementAdjuster(bounds: [3210.0, 9024.0], rates: [1.12, 1.16]),
                NetworkAgreementRateOffsetAdjuster(weight: 0.27),
                FlaggedNetworkAgreementAdjuster(flags: flags, flag: "network-agreement-seasonal", percent: -2.8),
                PercentNetworkAgreementAdjuster(percent: -9.2),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 79889.1
        )
    }
}
