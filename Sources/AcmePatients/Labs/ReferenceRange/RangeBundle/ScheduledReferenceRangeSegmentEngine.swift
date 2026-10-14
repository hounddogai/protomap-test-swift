import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled reference range segment calculation.
    protocol ScheduledReferenceRangeSegmentStep {
        func describe() -> String
        func adjust(_ item: ScheduledReferenceRangeSegment, value: Double) -> Double
    }

    final class FlaggedScheduledReferenceRangeSegmentAdjuster: ScheduledReferenceRangeSegmentStep {
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

        func adjust(_ item: ScheduledReferenceRangeSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledReferenceRangeSegmentAdjuster: ScheduledReferenceRangeSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledReferenceRangeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledReferenceRangeSegmentAdjuster: ScheduledReferenceRangeSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledReferenceRangeSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled reference range segment steps in order and keeps a trace of each.
    final class ScheduledReferenceRangeSegmentEngine {
        var steps: [any ScheduledReferenceRangeSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledReferenceRangeSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledReferenceRangeSegment) -> Double {
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

        func evaluateAll(_ items: [ScheduledReferenceRangeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledReferenceRangeSegmentEngine(_ flags: Kit.Flags.Registry) -> ScheduledReferenceRangeSegmentEngine {
        return ScheduledReferenceRangeSegmentEngine(
            steps: [
                FlaggedScheduledReferenceRangeSegmentAdjuster(
                    flags: flags,
                    flag: "scheduled-reference-range-segment-scheduled",
                    percent: -6.8
                ),
                TieredScheduledReferenceRangeSegmentAdjuster(
                    bounds: [485.0, 3013.0, 8553.0],
                    rates: [0.93, 1.1, 1.01]
                ),
                CapScheduledReferenceRangeSegmentAdjuster(cap: 13111.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 7058.3
        )
    }
}
