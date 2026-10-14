import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending reference range batch calculation.
    protocol PendingReferenceRangeBatchFactor {
        func describe() -> String
        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double
    }

    final class CapPendingReferenceRangeBatchAdjuster: PendingReferenceRangeBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingReferenceRangeBatchAdjuster: PendingReferenceRangeBatchFactor {
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

        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryPendingReferenceRangeBatchAdjuster: PendingReferenceRangeBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingReferenceRangeBatchAdjuster: PendingReferenceRangeBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingReferenceRangeBatchAdjuster: PendingReferenceRangeBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingReferenceRangeBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending reference range batch steps in order and keeps a trace of each.
    final class PendingReferenceRangeBatchEngine {
        var steps: [any PendingReferenceRangeBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingReferenceRangeBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingReferenceRangeBatch) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingReferenceRangeBatchFactor = steps[index]
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

        func evaluateAll(_ items: [PendingReferenceRangeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingReferenceRangeBatchEngine(_ flags: Kit.Flags.Registry) -> PendingReferenceRangeBatchEngine {
        return PendingReferenceRangeBatchEngine(
            steps: [
                CapPendingReferenceRangeBatchAdjuster(cap: 21316.0),
                FlaggedPendingReferenceRangeBatchAdjuster(
                    flags: flags,
                    flag: "pending-reference-range-batch-capped",
                    percent: 6.2
                ),
                CategoryPendingReferenceRangeBatchAdjuster(factors: ["north": 1.11, "east": 0.99]),
                PercentPendingReferenceRangeBatchAdjuster(percent: 8.5),
                TieredPendingReferenceRangeBatchAdjuster(bounds: [2682.0, 9221.0], rates: [1.2, 1.19]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 7605.4
        )
    }
}
