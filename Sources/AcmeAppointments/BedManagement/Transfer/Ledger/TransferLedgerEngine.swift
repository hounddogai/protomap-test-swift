import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer ledger calculation.
    protocol TransferLedgerFactor {
        func describe() -> String
        func adjust(_ item: TransferLedger, value: Double) -> Double
    }

    final class TransferLedgerSequenceOffsetAdjuster: TransferLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: TransferLedger, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class ChannelTransferLedgerAdjuster: TransferLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TransferLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTransferLedgerAdjuster: TransferLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the transfer ledger steps in order and keeps a trace of each.
    final class TransferLedgerEngine {
        var steps: [any TransferLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferLedger) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [TransferLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferLedgerEngine() -> TransferLedgerEngine {
        return TransferLedgerEngine(
            steps: [
                TransferLedgerSequenceOffsetAdjuster(weight: 1.65),
                ChannelTransferLedgerAdjuster(factors: ["east": 1.14, "central": 0.97]),
                CapTransferLedgerAdjuster(cap: 1871.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 7098.8
        )
    }
}
