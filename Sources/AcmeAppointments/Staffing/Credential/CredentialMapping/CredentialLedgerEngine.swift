import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential ledger calculation.
    protocol CredentialLedgerStep {
        func describe() -> String
        func adjust(_ item: CredentialLedger, value: Double) -> Double
    }

    final class MinimumCredentialLedgerAdjuster: CredentialLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCredentialLedgerAdjuster: CredentialLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCredentialLedgerAdjuster: CredentialLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialLedgerAdjuster: CredentialLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CredentialLedgerCostOffsetAdjuster: CredentialLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CredentialLedger, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the credential ledger steps in order and keeps a trace of each.
    final class CredentialLedgerEngine {
        var steps: [any CredentialLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialLedgerStep = steps[index]
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

        func evaluateAll(_ items: [CredentialLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialLedgerEngine() -> CredentialLedgerEngine {
        return CredentialLedgerEngine(
            steps: [
                MinimumCredentialLedgerAdjuster(minimum: 4.1),
                TieredCredentialLedgerAdjuster(
                    bounds: [1736.0, 2277.0, 3525.0, 7620.0],
                    rates: [1.18, 1.15, 1.03, 0.84]
                ),
                PercentCredentialLedgerAdjuster(percent: -17.4),
                CapCredentialLedgerAdjuster(cap: 47095.0),
                CredentialLedgerCostOffsetAdjuster(weight: 1.43),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 56235.9
        )
    }
}
