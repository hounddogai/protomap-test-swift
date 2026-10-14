import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient closure notice calculation.
    protocol LenientClosureNoticeFactor {
        func describe() -> String
        func adjust(_ item: LenientClosureNotice, value: Double) -> Double
    }

    final class FlaggedLenientClosureNoticeAdjuster: LenientClosureNoticeFactor {
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

        func adjust(_ item: LenientClosureNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientClosureNoticeGraceDaysOffsetAdjuster: LenientClosureNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LenientClosureNotice, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingLenientClosureNoticeAdjuster: LenientClosureNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientClosureNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLenientClosureNoticeAdjuster: LenientClosureNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientClosureNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientClosureNoticeAdjuster: LenientClosureNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientClosureNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient closure notice steps in order and keeps a trace of each.
    final class LenientClosureNoticeEngine {
        var steps: [any LenientClosureNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientClosureNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientClosureNotice) -> Double {
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

        func evaluateAll(_ items: [LenientClosureNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientClosureNoticeEngine(_ flags: Kit.Flags.Registry) -> LenientClosureNoticeEngine {
        return LenientClosureNoticeEngine(
            steps: [
                FlaggedLenientClosureNoticeAdjuster(
                    flags: flags,
                    flag: "lenient-closure-notice-scheduled",
                    percent: -7.6
                ),
                LenientClosureNoticeGraceDaysOffsetAdjuster(weight: 1.2),
                RoundingLenientClosureNoticeAdjuster(step: 0.1),
                PercentLenientClosureNoticeAdjuster(percent: -16.6),
                TieredLenientClosureNoticeAdjuster(bounds: [2890.0, 3241.0, 3669.0], rates: [1.01, 1.06, 0.98]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 50011.1
        )
    }
}
