import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen ledger calculation.
    protocol AdaptiveSpecimenLedgerFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenLedger, value: Double) -> Double
    }

    final class PercentAdaptiveSpecimenLedgerAdjuster: AdaptiveSpecimenLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveSpecimenLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveSpecimenLedgerAdjuster: AdaptiveSpecimenLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSpecimenLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveSpecimenLedgerAdjuster: AdaptiveSpecimenLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSpecimenLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveSpecimenLedgerAdjuster: AdaptiveSpecimenLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveSpecimenLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive specimen ledger steps in order and keeps a trace of each.
    final class AdaptiveSpecimenLedgerEngine {
        var steps: [any AdaptiveSpecimenLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveSpecimenLedger) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AdaptiveSpecimenLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenLedgerEngine() -> AdaptiveSpecimenLedgerEngine {
        return AdaptiveSpecimenLedgerEngine(
            steps: [
                PercentAdaptiveSpecimenLedgerAdjuster(percent: 5.1),
                TieredAdaptiveSpecimenLedgerAdjuster(
                    bounds: [2317.0, 6758.0, 7573.0, 8431.0],
                    rates: [0.88, 0.86, 1.03, 1.13]
                ),
                RoundingAdaptiveSpecimenLedgerAdjuster(step: 0.25),
                MinimumAdaptiveSpecimenLedgerAdjuster(minimum: 32.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 95769.8
        )
    }
}
