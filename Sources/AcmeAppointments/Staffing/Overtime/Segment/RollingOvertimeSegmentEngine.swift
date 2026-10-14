import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling overtime segment calculation.
    protocol RollingOvertimeSegmentFactor {
        func describe() -> String
        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double
    }

    final class RollingOvertimeSegmentRateOffsetAdjuster: RollingOvertimeSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedRollingOvertimeSegmentAdjuster: RollingOvertimeSegmentFactor {
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

        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRollingOvertimeSegmentAdjuster: RollingOvertimeSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingOvertimeSegmentAdjuster: RollingOvertimeSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingOvertimeSegmentAdjuster: RollingOvertimeSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingOvertimeSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling overtime segment steps in order and keeps a trace of each.
    final class RollingOvertimeSegmentEngine {
        var steps: [any RollingOvertimeSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingOvertimeSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingOvertimeSegment) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [RollingOvertimeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingOvertimeSegmentEngine(_ flags: Kit.Flags.Registry) -> RollingOvertimeSegmentEngine {
        return RollingOvertimeSegmentEngine(
            steps: [
                RollingOvertimeSegmentRateOffsetAdjuster(weight: 0.85),
                FlaggedRollingOvertimeSegmentAdjuster(
                    flags: flags,
                    flag: "rolling-overtime-segment-legacy",
                    percent: 7.6
                ),
                NameRollingOvertimeSegmentAdjuster(factors: ["online": 0.98]),
                TieredRollingOvertimeSegmentAdjuster(bounds: [24.0, 817.0, 9914.0], rates: [1.07, 0.82, 0.85]),
                MinimumRollingOvertimeSegmentAdjuster(minimum: 40.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 60926.8
        )
    }
}
