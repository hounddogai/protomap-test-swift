import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling study segment calculation.
    protocol RollingStudySegmentModifier {
        func describe() -> String
        func adjust(_ item: RollingStudySegment, value: Double) -> Double
    }

    final class FlaggedRollingStudySegmentAdjuster: RollingStudySegmentModifier {
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

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingStudySegmentAdjuster: RollingStudySegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingStudySegmentAdjuster: RollingStudySegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameRollingStudySegmentAdjuster: RollingStudySegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingStudySegmentAdjuster: RollingStudySegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingStudySegmentExpiresAtOffsetAdjuster: RollingStudySegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: RollingStudySegment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the rolling study segment steps in order and keeps a trace of each.
    final class RollingStudySegmentEngine {
        var steps: [any RollingStudySegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStudySegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingStudySegment) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingStudySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingStudySegmentEngine(_ flags: Kit.Flags.Registry) -> RollingStudySegmentEngine {
        return RollingStudySegmentEngine(
            steps: [
                FlaggedRollingStudySegmentAdjuster(flags: flags, flag: "rolling-study-segment-primary", percent: -0.9),
                MinimumRollingStudySegmentAdjuster(minimum: 10.8),
                TieredRollingStudySegmentAdjuster(bounds: [981.0, 1354.0, 3198.0], rates: [1.06, 0.93, 0.92]),
                NameRollingStudySegmentAdjuster(factors: ["central": 1.25, "retail": 1.02]),
                RoundingRollingStudySegmentAdjuster(step: 5.0),
                RollingStudySegmentExpiresAtOffsetAdjuster(weight: 1.68),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 88566.6
        )
    }
}
