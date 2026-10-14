import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert ledger calculation.
    protocol AlertLedgerFactor {
        func describe() -> String
        func adjust(_ item: AlertLedger, value: Double) -> Double
    }

    final class CapAlertLedgerAdjuster: AlertLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAlertLedgerAdjuster: AlertLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AlertLedgerRatioOffsetAdjuster: AlertLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingAlertLedgerAdjuster: AlertLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAlertLedgerAdjuster: AlertLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAlertLedgerAdjuster: AlertLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the alert ledger steps in order and keeps a trace of each.
    final class AlertLedgerEngine {
        var steps: [any AlertLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertLedger) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [AlertLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertLedgerEngine() -> AlertLedgerEngine {
        return AlertLedgerEngine(
            steps: [
                CapAlertLedgerAdjuster(cap: 38764.0),
                TieredAlertLedgerAdjuster(bounds: [3046.0, 8742.0, 9647.0], rates: [0.93, 1.07, 1.11]),
                AlertLedgerRatioOffsetAdjuster(weight: 0.84),
                RoundingAlertLedgerAdjuster(step: 0.05),
                PercentAlertLedgerAdjuster(percent: 7.2),
                MinimumAlertLedgerAdjuster(minimum: 42.3),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 29450.2
        )
    }
}
