import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling assessment notice calculation.
    protocol RollingAssessmentNoticeModifier {
        func describe() -> String
        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double
    }

    final class RollingAssessmentNoticeVersionOffsetAdjuster: RollingAssessmentNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class PercentRollingAssessmentNoticeAdjuster: RollingAssessmentNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingAssessmentNoticeAdjuster: RollingAssessmentNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingAssessmentNoticeAdjuster: RollingAssessmentNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingAssessmentNoticeAdjuster: RollingAssessmentNoticeModifier {
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

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardRollingAssessmentNoticeAdjuster: RollingAssessmentNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingAssessmentNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling assessment notice steps in order and keeps a trace of each.
    final class RollingAssessmentNoticeEngine {
        var steps: [any RollingAssessmentNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAssessmentNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingAssessmentNotice) -> Double {
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

        func evaluateAll(_ items: [RollingAssessmentNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingAssessmentNoticeEngine(_ flags: Kit.Flags.Registry) -> RollingAssessmentNoticeEngine {
        return RollingAssessmentNoticeEngine(
            steps: [
                RollingAssessmentNoticeVersionOffsetAdjuster(weight: 0.52),
                PercentRollingAssessmentNoticeAdjuster(percent: 19.5),
                MinimumRollingAssessmentNoticeAdjuster(minimum: 6.0),
                TieredRollingAssessmentNoticeAdjuster(bounds: [2180.0, 6484.0, 8786.0], rates: [1.17, 0.93, 0.85]),
                FlaggedRollingAssessmentNoticeAdjuster(
                    flags: flags,
                    flag: "rolling-assessment-notice-seasonal",
                    percent: 6.5
                ),
                WardRollingAssessmentNoticeAdjuster(factors: ["online": 1.25, "retail": 1.05]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 85051.7
        )
    }
}
