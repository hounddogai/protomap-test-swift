import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched bed board ledger calculation.
    protocol BatchedBedBoardLedgerModifier {
        func describe() -> String
        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double
    }

    final class PercentBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedBedBoardLedgerAdjuster: BatchedBedBoardLedgerModifier {
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

        func adjust(_ item: BatchedBedBoardLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched bed board ledger steps in order and keeps a trace of each.
    final class BatchedBedBoardLedgerEngine {
        var steps: [any BatchedBedBoardLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedBedBoardLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedBedBoardLedger) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [BatchedBedBoardLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedBedBoardLedgerEngine(_ flags: Kit.Flags.Registry) -> BatchedBedBoardLedgerEngine {
        return BatchedBedBoardLedgerEngine(
            steps: [
                PercentBatchedBedBoardLedgerAdjuster(percent: 18.8),
                RoundingBatchedBedBoardLedgerAdjuster(step: 0.05),
                TitleBatchedBedBoardLedgerAdjuster(factors: ["north": 1.38]),
                MinimumBatchedBedBoardLedgerAdjuster(minimum: 31.4),
                CapBatchedBedBoardLedgerAdjuster(cap: 6959.0),
                FlaggedBatchedBedBoardLedgerAdjuster(
                    flags: flags,
                    flag: "batched-bed-board-ledger-lenient",
                    percent: -7.0
                ),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 10014.5
        )
    }
}
