import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling formulary segment calculation.
    protocol RollingFormularySegmentFactor {
        func describe() -> String
        func adjust(_ item: RollingFormularySegment, value: Double) -> Double
    }

    final class TieredRollingFormularySegmentAdjuster: RollingFormularySegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFormularySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingFormularySegmentAdjuster: RollingFormularySegmentFactor {
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

        func adjust(_ item: RollingFormularySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingFormularySegmentUpdatedAtOffsetAdjuster: RollingFormularySegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RollingFormularySegment, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentRollingFormularySegmentAdjuster: RollingFormularySegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFormularySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling formulary segment steps in order and keeps a trace of each.
    final class RollingFormularySegmentEngine {
        var steps: [any RollingFormularySegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFormularySegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingFormularySegment) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingFormularySegmentFactor = steps[index]
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

        func evaluateAll(_ items: [RollingFormularySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingFormularySegmentEngine(_ flags: Kit.Flags.Registry) -> RollingFormularySegmentEngine {
        return RollingFormularySegmentEngine(
            steps: [
                TieredRollingFormularySegmentAdjuster(bounds: [6938.0, 7801.0], rates: [0.82, 1.08]),
                FlaggedRollingFormularySegmentAdjuster(
                    flags: flags,
                    flag: "rolling-formulary-segment-capped",
                    percent: -8.7
                ),
                RollingFormularySegmentUpdatedAtOffsetAdjuster(weight: 1.87),
                PercentRollingFormularySegmentAdjuster(percent: 11.6),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 46280.1
        )
    }
}
