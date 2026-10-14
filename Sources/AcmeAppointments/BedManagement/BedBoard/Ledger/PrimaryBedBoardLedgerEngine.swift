import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary bed board ledger calculation.
    protocol PrimaryBedBoardLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryBedBoardLedger, value: Double) -> Double
    }

    final class FlaggedPrimaryBedBoardLedgerAdjuster: PrimaryBedBoardLedgerAdjuster {
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

        func adjust(_ item: PrimaryBedBoardLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPrimaryBedBoardLedgerAdjuster: PrimaryBedBoardLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryBedBoardLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryBedBoardLedgerAdjuster: PrimaryBedBoardLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryBedBoardLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary bed board ledger steps in order and keeps a trace of each.
    final class PrimaryBedBoardLedgerEngine {
        var steps: [any PrimaryBedBoardLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryBedBoardLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryBedBoardLedger) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryBedBoardLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryBedBoardLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryBedBoardLedgerEngine(_ flags: Kit.Flags.Registry) -> PrimaryBedBoardLedgerEngine {
        return PrimaryBedBoardLedgerEngine(
            steps: [
                FlaggedPrimaryBedBoardLedgerAdjuster(
                    flags: flags,
                    flag: "primary-bed-board-ledger-lenient",
                    percent: 8.8
                ),
                LabelPrimaryBedBoardLedgerAdjuster(factors: ["east": 1.37, "north": 1.24]),
                TieredPrimaryBedBoardLedgerAdjuster(bounds: [3777.0, 4119.0], rates: [0.99, 0.89]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 8202.1
        )
    }
}
