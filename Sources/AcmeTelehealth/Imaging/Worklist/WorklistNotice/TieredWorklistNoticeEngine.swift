import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered worklist notice calculation.
    protocol TieredWorklistNoticeStep {
        func describe() -> String
        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double
    }

    final class TieredTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
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

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredWorklistNoticeAdjuster: TieredWorklistNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredWorklistNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered worklist notice steps in order and keeps a trace of each.
    final class TieredWorklistNoticeEngine {
        var steps: [any TieredWorklistNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredWorklistNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredWorklistNotice) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredWorklistNoticeStep = steps[index]
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

        func evaluateAll(_ items: [TieredWorklistNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredWorklistNoticeEngine(_ flags: Kit.Flags.Registry) -> TieredWorklistNoticeEngine {
        return TieredWorklistNoticeEngine(
            steps: [
                TieredTieredWorklistNoticeAdjuster(bounds: [4947.0, 8008.0], rates: [0.98, 0.96]),
                CapTieredWorklistNoticeAdjuster(cap: 18573.0),
                FlaggedTieredWorklistNoticeAdjuster(flags: flags, flag: "tiered-worklist-notice-global", percent: 5.2),
                PercentTieredWorklistNoticeAdjuster(percent: -19.4),
                MinimumTieredWorklistNoticeAdjuster(minimum: 26.4),
                RoundingTieredWorklistNoticeAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 2754.8
        )
    }
}
