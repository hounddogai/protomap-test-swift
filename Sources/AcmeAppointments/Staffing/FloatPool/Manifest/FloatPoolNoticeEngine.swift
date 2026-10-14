import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool notice calculation.
    protocol FloatPoolNoticeFactor {
        func describe() -> String
        func adjust(_ item: FloatPoolNotice, value: Double) -> Double
    }

    final class PercentFloatPoolNoticeAdjuster: FloatPoolNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFloatPoolNoticeAdjuster: FloatPoolNoticeFactor {
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

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFloatPoolNoticeAdjuster: FloatPoolNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFloatPoolNoticeAdjuster: FloatPoolNoticeFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FloatPoolNoticeLimitOffsetAdjuster: FloatPoolNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CountryFloatPoolNoticeAdjuster: FloatPoolNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FloatPoolNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool notice steps in order and keeps a trace of each.
    final class FloatPoolNoticeEngine {
        var steps: [any FloatPoolNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolNotice) -> Double {
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

        func evaluateAll(_ items: [FloatPoolNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolNoticeEngine(_ flags: Kit.Flags.Registry) -> FloatPoolNoticeEngine {
        return FloatPoolNoticeEngine(
            steps: [
                PercentFloatPoolNoticeAdjuster(percent: -11.0),
                FlaggedFloatPoolNoticeAdjuster(flags: flags, flag: "float-pool-notice-lenient", percent: -2.5),
                RoundingFloatPoolNoticeAdjuster(step: 0.05),
                MinimumFloatPoolNoticeAdjuster(minimum: 45.1),
                FloatPoolNoticeLimitOffsetAdjuster(weight: 1.47),
                CountryFloatPoolNoticeAdjuster(factors: ["retail": 0.89, "south": 1.32, "north": 0.75]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 94089.4
        )
    }
}
