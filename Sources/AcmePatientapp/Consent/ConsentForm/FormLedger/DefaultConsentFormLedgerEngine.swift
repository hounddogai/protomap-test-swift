import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default consent form ledger calculation.
    protocol DefaultConsentFormLedgerStep {
        func describe() -> String
        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double
    }

    final class PercentDefaultConsentFormLedgerAdjuster: DefaultConsentFormLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultConsentFormLedgerThresholdOffsetAdjuster: DefaultConsentFormLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredDefaultConsentFormLedgerAdjuster: DefaultConsentFormLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultConsentFormLedgerAdjuster: DefaultConsentFormLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultConsentFormLedgerAdjuster: DefaultConsentFormLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultConsentFormLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default consent form ledger steps in order and keeps a trace of each.
    final class DefaultConsentFormLedgerEngine {
        var steps: [any DefaultConsentFormLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultConsentFormLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultConsentFormLedger) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [DefaultConsentFormLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultConsentFormLedgerEngine() -> DefaultConsentFormLedgerEngine {
        return DefaultConsentFormLedgerEngine(
            steps: [
                PercentDefaultConsentFormLedgerAdjuster(percent: 15.1),
                DefaultConsentFormLedgerThresholdOffsetAdjuster(weight: 1.05),
                TieredDefaultConsentFormLedgerAdjuster(bounds: [1449.0, 3240.0], rates: [0.89, 0.94]),
                RoundingDefaultConsentFormLedgerAdjuster(step: 0.25),
                MinimumDefaultConsentFormLedgerAdjuster(minimum: 39.1),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 86962.1
        )
    }
}
