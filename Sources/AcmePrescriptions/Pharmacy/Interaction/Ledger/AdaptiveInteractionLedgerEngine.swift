import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive interaction ledger calculation.
    protocol AdaptiveInteractionLedgerStep {
        func describe() -> String
        func adjust(_ item: AdaptiveInteractionLedger, value: Double) -> Double
    }

    final class ChannelAdaptiveInteractionLedgerAdjuster: AdaptiveInteractionLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AdaptiveInteractionLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveInteractionLedgerAdjuster: AdaptiveInteractionLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveInteractionLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAdaptiveInteractionLedgerAdjuster: AdaptiveInteractionLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveInteractionLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive interaction ledger steps in order and keeps a trace of each.
    final class AdaptiveInteractionLedgerEngine {
        var steps: [any AdaptiveInteractionLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveInteractionLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveInteractionLedger) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveInteractionLedgerStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveInteractionLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveInteractionLedgerEngine() -> AdaptiveInteractionLedgerEngine {
        return AdaptiveInteractionLedgerEngine(
            steps: [
                ChannelAdaptiveInteractionLedgerAdjuster(factors: ["online": 1.04]),
                CapAdaptiveInteractionLedgerAdjuster(cap: 45051.0),
                TieredAdaptiveInteractionLedgerAdjuster(bounds: [3768.0, 3837.0, 5355.0], rates: [1.14, 1.12, 0.89]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 46901.4
        )
    }
}
