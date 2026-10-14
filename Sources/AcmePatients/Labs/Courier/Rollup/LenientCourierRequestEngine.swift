import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient courier request calculation.
    protocol LenientCourierRequestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientCourierRequest, value: Double) -> Double
    }

    final class TieredLenientCourierRequestAdjuster: LenientCourierRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientCourierRequestAdjuster: LenientCourierRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientCourierRequestGraceDaysOffsetAdjuster: LenientCourierRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumLenientCourierRequestAdjuster: LenientCourierRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLenientCourierRequestAdjuster: LenientCourierRequestAdjuster {
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

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCourierRequestAdjuster: LenientCourierRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCourierRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient courier request steps in order and keeps a trace of each.
    final class LenientCourierRequestEngine {
        var steps: [any LenientCourierRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCourierRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCourierRequest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCourierRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientCourierRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCourierRequestEngine(_ flags: Kit.Flags.Registry) -> LenientCourierRequestEngine {
        return LenientCourierRequestEngine(
            steps: [
                TieredLenientCourierRequestAdjuster(bounds: [427.0, 767.0, 8370.0], rates: [0.97, 0.85, 0.85]),
                PercentLenientCourierRequestAdjuster(percent: 14.4),
                LenientCourierRequestGraceDaysOffsetAdjuster(weight: 0.56),
                MinimumLenientCourierRequestAdjuster(minimum: 45.1),
                FlaggedLenientCourierRequestAdjuster(
                    flags: flags,
                    flag: "lenient-courier-request-fallback",
                    percent: 7.4
                ),
                RoundingLenientCourierRequestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 42135.0
        )
    }
}
