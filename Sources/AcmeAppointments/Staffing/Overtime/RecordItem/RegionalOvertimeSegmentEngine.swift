import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional overtime segment calculation.
    protocol RegionalOvertimeSegmentFactor {
        func describe() -> String
        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double
    }

    final class PercentRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
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

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalOvertimeSegmentAdjuster: RegionalOvertimeSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOvertimeSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional overtime segment steps in order and keeps a trace of each.
    final class RegionalOvertimeSegmentEngine {
        var steps: [any RegionalOvertimeSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOvertimeSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalOvertimeSegment) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [RegionalOvertimeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalOvertimeSegmentEngine(_ flags: Kit.Flags.Registry) -> RegionalOvertimeSegmentEngine {
        return RegionalOvertimeSegmentEngine(
            steps: [
                PercentRegionalOvertimeSegmentAdjuster(percent: 24.3),
                TieredRegionalOvertimeSegmentAdjuster(
                    bounds: [1175.0, 1196.0, 3940.0, 3944.0],
                    rates: [1.14, 1.09, 1.08, 1.03]
                ),
                CapRegionalOvertimeSegmentAdjuster(cap: 44532.0),
                FlaggedRegionalOvertimeSegmentAdjuster(
                    flags: flags,
                    flag: "regional-overtime-segment-legacy",
                    percent: -6.8
                ),
                RoundingRegionalOvertimeSegmentAdjuster(step: 0.05),
                MinimumRegionalOvertimeSegmentAdjuster(minimum: 6.2),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 3603.2
        )
    }
}
