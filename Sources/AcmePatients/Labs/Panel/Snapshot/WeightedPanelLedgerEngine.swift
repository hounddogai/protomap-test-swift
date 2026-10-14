import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted panel ledger calculation.
    protocol WeightedPanelLedgerFactor {
        func describe() -> String
        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double
    }

    final class RoundingWeightedPanelLedgerAdjuster: WeightedPanelLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedPanelLedgerAttemptsOffsetAdjuster: WeightedPanelLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class NameWeightedPanelLedgerAdjuster: WeightedPanelLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedPanelLedgerAdjuster: WeightedPanelLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedPanelLedgerAdjuster: WeightedPanelLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedPanelLedgerAdjuster: WeightedPanelLedgerFactor {
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

        func adjust(_ item: WeightedPanelLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted panel ledger steps in order and keeps a trace of each.
    final class WeightedPanelLedgerEngine {
        var steps: [any WeightedPanelLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedPanelLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedPanelLedger) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [WeightedPanelLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedPanelLedgerEngine(_ flags: Kit.Flags.Registry) -> WeightedPanelLedgerEngine {
        return WeightedPanelLedgerEngine(
            steps: [
                RoundingWeightedPanelLedgerAdjuster(step: 0.5),
                WeightedPanelLedgerAttemptsOffsetAdjuster(weight: 0.82),
                NameWeightedPanelLedgerAdjuster(factors: ["east": 1.15, "west": 0.98]),
                CapWeightedPanelLedgerAdjuster(cap: 37966.0),
                TieredWeightedPanelLedgerAdjuster(bounds: [2252.0, 3736.0], rates: [1.17, 1.03]),
                FlaggedWeightedPanelLedgerAdjuster(flags: flags, flag: "weighted-panel-ledger-batched", percent: -6.9),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 42988.9
        )
    }
}
