import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped closure notice calculation.
    protocol CappedClosureNoticeModifier {
        func describe() -> String
        func adjust(_ item: CappedClosureNotice, value: Double) -> Double
    }

    final class CappedClosureNoticeRateOffsetAdjuster: CappedClosureNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentCappedClosureNoticeAdjuster: CappedClosureNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedClosureNoticeAdjuster: CappedClosureNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedClosureNoticeAdjuster: CappedClosureNoticeModifier {
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

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityCappedClosureNoticeAdjuster: CappedClosureNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedClosureNoticeAdjuster: CappedClosureNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedClosureNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped closure notice steps in order and keeps a trace of each.
    final class CappedClosureNoticeEngine {
        var steps: [any CappedClosureNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedClosureNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedClosureNotice) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedClosureNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [CappedClosureNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedClosureNoticeEngine(_ flags: Kit.Flags.Registry) -> CappedClosureNoticeEngine {
        return CappedClosureNoticeEngine(
            steps: [
                CappedClosureNoticeRateOffsetAdjuster(weight: 1.18),
                PercentCappedClosureNoticeAdjuster(percent: 7.9),
                TieredCappedClosureNoticeAdjuster(bounds: [6643.0, 9501.0], rates: [1.17, 0.81]),
                FlaggedCappedClosureNoticeAdjuster(flags: flags, flag: "capped-closure-notice-global", percent: -1.2),
                FacilityCappedClosureNoticeAdjuster(factors: ["south": 1.3]),
                MinimumCappedClosureNoticeAdjuster(minimum: 21.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 80326.4
        )
    }
}
