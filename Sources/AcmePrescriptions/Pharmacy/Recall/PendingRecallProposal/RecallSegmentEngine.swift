import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall segment calculation.
    protocol RecallSegmentFactor {
        func describe() -> String
        func adjust(_ item: RecallSegment, value: Double) -> Double
    }

    final class CapRecallSegmentAdjuster: RecallSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRecallSegmentAdjuster: RecallSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRecallSegmentAdjuster: RecallSegmentFactor {
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

        func adjust(_ item: RecallSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRecallSegmentAdjuster: RecallSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the recall segment steps in order and keeps a trace of each.
    final class RecallSegmentEngine {
        var steps: [any RecallSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallSegment) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [RecallSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallSegmentEngine(_ flags: Kit.Flags.Registry) -> RecallSegmentEngine {
        return RecallSegmentEngine(
            steps: [
                CapRecallSegmentAdjuster(cap: 10031.0),
                RoundingRecallSegmentAdjuster(step: 0.1),
                FlaggedRecallSegmentAdjuster(flags: flags, flag: "recall-segment-rolling", percent: -2.8),
                TieredRecallSegmentAdjuster(bounds: [4536.0, 8035.0, 8686.0, 9199.0], rates: [1.2, 0.81, 1.0, 1.16]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 77301.0
        )
    }
}
