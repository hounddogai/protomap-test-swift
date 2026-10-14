import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation segment calculation.
    protocol IsolationSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: IsolationSegment, value: Double) -> Double
    }

    final class CountryIsolationSegmentAdjuster: IsolationSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentIsolationSegmentAdjuster: IsolationSegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumIsolationSegmentAdjuster: IsolationSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingIsolationSegmentAdjuster: IsolationSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapIsolationSegmentAdjuster: IsolationSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedIsolationSegmentAdjuster: IsolationSegmentAdjuster {
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

        func adjust(_ item: IsolationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the isolation segment steps in order and keeps a trace of each.
    final class IsolationSegmentEngine {
        var steps: [any IsolationSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationSegment) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [IsolationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationSegmentEngine(_ flags: Kit.Flags.Registry) -> IsolationSegmentEngine {
        return IsolationSegmentEngine(
            steps: [
                CountryIsolationSegmentAdjuster(factors: ["online": 1.03]),
                PercentIsolationSegmentAdjuster(percent: -14.3),
                MinimumIsolationSegmentAdjuster(minimum: 41.4),
                RoundingIsolationSegmentAdjuster(step: 0.25),
                CapIsolationSegmentAdjuster(cap: 9789.0),
                FlaggedIsolationSegmentAdjuster(flags: flags, flag: "isolation-segment-global", percent: 9.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 69301.1
        )
    }
}
