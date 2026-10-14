import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled isolation segment calculation.
    protocol ScheduledIsolationSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double
    }

    final class ScheduledIsolationSegmentWeightOffsetAdjuster: ScheduledIsolationSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class MinimumScheduledIsolationSegmentAdjuster: ScheduledIsolationSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledIsolationSegmentAdjuster: ScheduledIsolationSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledIsolationSegmentAdjuster: ScheduledIsolationSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledIsolationSegmentAdjuster: ScheduledIsolationSegmentAdjuster {
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

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameScheduledIsolationSegmentAdjuster: ScheduledIsolationSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledIsolationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled isolation segment steps in order and keeps a trace of each.
    final class ScheduledIsolationSegmentEngine {
        var steps: [any ScheduledIsolationSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledIsolationSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledIsolationSegment) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledIsolationSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledIsolationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledIsolationSegmentEngine(_ flags: Kit.Flags.Registry) -> ScheduledIsolationSegmentEngine {
        return ScheduledIsolationSegmentEngine(
            steps: [
                ScheduledIsolationSegmentWeightOffsetAdjuster(weight: 1.51),
                MinimumScheduledIsolationSegmentAdjuster(minimum: 20.9),
                TieredScheduledIsolationSegmentAdjuster(bounds: [603.0, 3802.0], rates: [1.18, 0.8]),
                RoundingScheduledIsolationSegmentAdjuster(step: 5.0),
                FlaggedScheduledIsolationSegmentAdjuster(
                    flags: flags,
                    flag: "scheduled-isolation-segment-weighted",
                    percent: -2.0
                ),
                NameScheduledIsolationSegmentAdjuster(factors: ["central": 1.14, "north": 0.8]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 75819.0
        )
    }
}
