import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted consent form ledger calculation.
    protocol WeightedConsentFormLedgerStep {
        func describe() -> String
        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double
    }

    final class MinimumWeightedConsentFormLedgerAdjuster: WeightedConsentFormLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedConsentFormLedgerAdjuster: WeightedConsentFormLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityWeightedConsentFormLedgerAdjuster: WeightedConsentFormLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedConsentFormLedgerAdjuster: WeightedConsentFormLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedConsentFormLedgerAdjuster: WeightedConsentFormLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedConsentFormLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted consent form ledger steps in order and keeps a trace of each.
    final class WeightedConsentFormLedgerEngine {
        var steps: [any WeightedConsentFormLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedConsentFormLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedConsentFormLedger) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedConsentFormLedgerStep = steps[index]
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

        func evaluateAll(_ items: [WeightedConsentFormLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedConsentFormLedgerEngine() -> WeightedConsentFormLedgerEngine {
        return WeightedConsentFormLedgerEngine(
            steps: [
                MinimumWeightedConsentFormLedgerAdjuster(minimum: 40.8),
                TieredWeightedConsentFormLedgerAdjuster(
                    bounds: [4691.0, 5036.0, 5818.0, 8893.0],
                    rates: [0.85, 0.89, 1.04, 1.07]
                ),
                FacilityWeightedConsentFormLedgerAdjuster(factors: ["south": 1.31, "east": 1.05]),
                PercentWeightedConsentFormLedgerAdjuster(percent: 15.0),
                CapWeightedConsentFormLedgerAdjuster(cap: 5620.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 98805.6
        )
    }
}
