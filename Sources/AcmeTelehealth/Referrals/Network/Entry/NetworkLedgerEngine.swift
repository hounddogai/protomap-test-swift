import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network ledger calculation.
    protocol NetworkLedgerStep {
        func describe() -> String
        func adjust(_ item: NetworkLedger, value: Double) -> Double
    }

    final class ChannelNetworkLedgerAdjuster: NetworkLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: NetworkLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentNetworkLedgerAdjuster: NetworkLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredNetworkLedgerAdjuster: NetworkLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the network ledger steps in order and keeps a trace of each.
    final class NetworkLedgerEngine {
        var steps: [any NetworkLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: NetworkLedger) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [NetworkLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultNetworkLedgerEngine() -> NetworkLedgerEngine {
        return NetworkLedgerEngine(
            steps: [
                ChannelNetworkLedgerAdjuster(factors: ["retail": 1.3, "east": 0.92]),
                PercentNetworkLedgerAdjuster(percent: 0.2),
                TieredNetworkLedgerAdjuster(bounds: [280.0, 8341.0, 9146.0], rates: [0.93, 0.84, 0.94]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 51753.1
        )
    }
}
