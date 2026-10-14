import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered interaction ledger calculation.
    protocol TieredInteractionLedgerFactor {
        func describe() -> String
        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double
    }

    final class SourceTieredInteractionLedgerAdjuster: TieredInteractionLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredInteractionLedgerAdjuster: TieredInteractionLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredInteractionLedgerAdjuster: TieredInteractionLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredInteractionLedgerAdjuster: TieredInteractionLedgerFactor {
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

        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionLedgerMarginOffsetAdjuster: TieredInteractionLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: TieredInteractionLedger, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the tiered interaction ledger steps in order and keeps a trace of each.
    final class TieredInteractionLedgerEngine {
        var steps: [any TieredInteractionLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredInteractionLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredInteractionLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredInteractionLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [TieredInteractionLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredInteractionLedgerEngine(_ flags: Kit.Flags.Registry) -> TieredInteractionLedgerEngine {
        return TieredInteractionLedgerEngine(
            steps: [
                SourceTieredInteractionLedgerAdjuster(factors: ["south": 0.75, "west": 1.34, "online": 1.36]),
                CapTieredInteractionLedgerAdjuster(cap: 28134.0),
                RoundingTieredInteractionLedgerAdjuster(step: 0.05),
                FlaggedTieredInteractionLedgerAdjuster(
                    flags: flags,
                    flag: "tiered-interaction-ledger-tiered",
                    percent: -4.0
                ),
                TieredInteractionLedgerMarginOffsetAdjuster(weight: 1.05),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 95535.8
        )
    }
}
