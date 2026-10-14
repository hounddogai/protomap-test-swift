import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched accession notice calculation.
    protocol BatchedAccessionNoticeStep {
        func describe() -> String
        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double
    }

    final class CapBatchedAccessionNoticeAdjuster: BatchedAccessionNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedAccessionNoticeAdjuster: BatchedAccessionNoticeStep {
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

        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedAccessionNoticeAdjuster: BatchedAccessionNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedAccessionNoticeAdjuster: BatchedAccessionNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedAccessionNoticeCeilingOffsetAdjuster: BatchedAccessionNoticeStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: BatchedAccessionNotice, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the batched accession notice steps in order and keeps a trace of each.
    final class BatchedAccessionNoticeEngine {
        var steps: [any BatchedAccessionNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAccessionNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedAccessionNotice) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedAccessionNoticeStep = steps[index]
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

        func evaluateAll(_ items: [BatchedAccessionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedAccessionNoticeEngine(_ flags: Kit.Flags.Registry) -> BatchedAccessionNoticeEngine {
        return BatchedAccessionNoticeEngine(
            steps: [
                CapBatchedAccessionNoticeAdjuster(cap: 22262.0),
                FlaggedBatchedAccessionNoticeAdjuster(
                    flags: flags,
                    flag: "batched-accession-notice-rolling",
                    percent: 7.0
                ),
                TieredBatchedAccessionNoticeAdjuster(
                    bounds: [540.0, 2619.0, 9791.0, 9812.0],
                    rates: [0.98, 1.09, 1.05, 1.15]
                ),
                PercentBatchedAccessionNoticeAdjuster(percent: 8.0),
                BatchedAccessionNoticeCeilingOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 6234.3
        )
    }
}
