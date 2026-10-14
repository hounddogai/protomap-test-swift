import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted slot ledger calculation.
    protocol WeightedSlotLedgerStep {
        func describe() -> String
        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double
    }

    final class TieredWeightedSlotLedgerAdjuster: WeightedSlotLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedSlotLedgerCopayOffsetAdjuster: WeightedSlotLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentWeightedSlotLedgerAdjuster: WeightedSlotLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedSlotLedgerAdjuster: WeightedSlotLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedWeightedSlotLedgerAdjuster: WeightedSlotLedgerStep {
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

        func adjust(_ item: WeightedSlotLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted slot ledger steps in order and keeps a trace of each.
    final class WeightedSlotLedgerEngine {
        var steps: [any WeightedSlotLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSlotLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedSlotLedger) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSlotLedgerStep = steps[index]
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

        func evaluateAll(_ items: [WeightedSlotLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedSlotLedgerEngine(_ flags: Kit.Flags.Registry) -> WeightedSlotLedgerEngine {
        return WeightedSlotLedgerEngine(
            steps: [
                TieredWeightedSlotLedgerAdjuster(bounds: [4360.0, 7432.0, 9991.0], rates: [1.02, 0.94, 0.95]),
                WeightedSlotLedgerCopayOffsetAdjuster(weight: 1.46),
                PercentWeightedSlotLedgerAdjuster(percent: 15.1),
                CapWeightedSlotLedgerAdjuster(cap: 2570.0),
                FlaggedWeightedSlotLedgerAdjuster(flags: flags, flag: "weighted-slot-ledger-capped", percent: 4.5),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 37960.4
        )
    }
}
