import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched study segment calculation.
    protocol BatchedStudySegmentAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedStudySegment, value: Double) -> Double
    }

    final class TieredBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
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

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedStudySegmentAdjuster: BatchedStudySegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedStudySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched study segment steps in order and keeps a trace of each.
    final class BatchedStudySegmentEngine {
        var steps: [any BatchedStudySegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStudySegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedStudySegment) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [BatchedStudySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedStudySegmentEngine(_ flags: Kit.Flags.Registry) -> BatchedStudySegmentEngine {
        return BatchedStudySegmentEngine(
            steps: [
                TieredBatchedStudySegmentAdjuster(bounds: [1843.0, 6044.0, 8571.0], rates: [1.03, 0.82, 1.17]),
                LabelBatchedStudySegmentAdjuster(factors: ["west": 0.75, "east": 0.93]),
                MinimumBatchedStudySegmentAdjuster(minimum: 1.5),
                FlaggedBatchedStudySegmentAdjuster(flags: flags, flag: "batched-study-segment-manual", percent: 8.5),
                PercentBatchedStudySegmentAdjuster(percent: 16.1),
                CapBatchedStudySegmentAdjuster(cap: 11266.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 25459.9
        )
    }
}
