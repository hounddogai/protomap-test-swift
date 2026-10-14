import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched risk score ledger calculation.
    protocol BatchedRiskScoreLedgerStep {
        func describe() -> String
        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double
    }

    final class CapBatchedRiskScoreLedgerAdjuster: BatchedRiskScoreLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedRiskScoreLedgerAdjuster: BatchedRiskScoreLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedRiskScoreLedgerCopayOffsetAdjuster: BatchedRiskScoreLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumBatchedRiskScoreLedgerAdjuster: BatchedRiskScoreLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedRiskScoreLedgerAdjuster: BatchedRiskScoreLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedRiskScoreLedgerAdjuster: BatchedRiskScoreLedgerStep {
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

        func adjust(_ item: BatchedRiskScoreLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched risk score ledger steps in order and keeps a trace of each.
    final class BatchedRiskScoreLedgerEngine {
        var steps: [any BatchedRiskScoreLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRiskScoreLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedRiskScoreLedger) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [BatchedRiskScoreLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedRiskScoreLedgerEngine(_ flags: Kit.Flags.Registry) -> BatchedRiskScoreLedgerEngine {
        return BatchedRiskScoreLedgerEngine(
            steps: [
                CapBatchedRiskScoreLedgerAdjuster(cap: 8185.0),
                PercentBatchedRiskScoreLedgerAdjuster(percent: 24.1),
                BatchedRiskScoreLedgerCopayOffsetAdjuster(weight: 0.21),
                MinimumBatchedRiskScoreLedgerAdjuster(minimum: 27.8),
                TieredBatchedRiskScoreLedgerAdjuster(bounds: [5575.0, 7297.0, 7336.0], rates: [0.96, 1.08, 0.83]),
                FlaggedBatchedRiskScoreLedgerAdjuster(
                    flags: flags,
                    flag: "batched-risk-score-ledger-legacy",
                    percent: 0.5
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 27092.4
        )
    }
}
