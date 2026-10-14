import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive network ledger calculation.
    protocol AdaptiveNetworkLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveNetworkLedger, value: Double) -> Double
    }

    final class MinimumAdaptiveNetworkLedgerAdjuster: AdaptiveNetworkLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveNetworkLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveNetworkLedgerAdjuster: AdaptiveNetworkLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveNetworkLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameAdaptiveNetworkLedgerAdjuster: AdaptiveNetworkLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveNetworkLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive network ledger steps in order and keeps a trace of each.
    final class AdaptiveNetworkLedgerEngine {
        var steps: [any AdaptiveNetworkLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveNetworkLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveNetworkLedger) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveNetworkLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveNetworkLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveNetworkLedgerEngine() -> AdaptiveNetworkLedgerEngine {
        return AdaptiveNetworkLedgerEngine(
            steps: [
                MinimumAdaptiveNetworkLedgerAdjuster(minimum: 22.2),
                CapAdaptiveNetworkLedgerAdjuster(cap: 6088.0),
                NameAdaptiveNetworkLedgerAdjuster(factors: ["west": 1.34, "east": 1.12]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 57187.0
        )
    }
}
