import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary closure notice calculation.
    protocol PrimaryClosureNoticeStep {
        func describe() -> String
        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double
    }

    final class TieredPrimaryClosureNoticeAdjuster: PrimaryClosureNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryClosureNoticeAdjuster: PrimaryClosureNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryClosureNoticeAdjuster: PrimaryClosureNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryClosureNoticeAdjuster: PrimaryClosureNoticeStep {
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

        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryClosureNoticeLimitOffsetAdjuster: PrimaryClosureNoticeStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: PrimaryClosureNotice, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the primary closure notice steps in order and keeps a trace of each.
    final class PrimaryClosureNoticeEngine {
        var steps: [any PrimaryClosureNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryClosureNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryClosureNotice) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryClosureNoticeStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryClosureNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryClosureNoticeEngine(_ flags: Kit.Flags.Registry) -> PrimaryClosureNoticeEngine {
        return PrimaryClosureNoticeEngine(
            steps: [
                TieredPrimaryClosureNoticeAdjuster(
                    bounds: [35.0, 602.0, 6015.0, 9798.0],
                    rates: [0.9, 0.92, 0.83, 0.92]
                ),
                RoundingPrimaryClosureNoticeAdjuster(step: 1.0),
                MinimumPrimaryClosureNoticeAdjuster(minimum: 18.7),
                FlaggedPrimaryClosureNoticeAdjuster(
                    flags: flags,
                    flag: "primary-closure-notice-pending",
                    percent: -6.6
                ),
                PrimaryClosureNoticeLimitOffsetAdjuster(weight: 1.39),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 30460.4
        )
    }
}
