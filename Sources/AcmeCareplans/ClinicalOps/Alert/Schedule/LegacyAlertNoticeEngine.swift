import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy alert notice calculation.
    protocol LegacyAlertNoticeStep {
        func describe() -> String
        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double
    }

    final class CapLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
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

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameLegacyAlertNoticeAdjuster: LegacyAlertNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyAlertNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy alert notice steps in order and keeps a trace of each.
    final class LegacyAlertNoticeEngine {
        var steps: [any LegacyAlertNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAlertNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyAlertNotice) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAlertNoticeStep = steps[index]
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

        func evaluateAll(_ items: [LegacyAlertNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyAlertNoticeEngine(_ flags: Kit.Flags.Registry) -> LegacyAlertNoticeEngine {
        return LegacyAlertNoticeEngine(
            steps: [
                CapLegacyAlertNoticeAdjuster(cap: 29090.0),
                TieredLegacyAlertNoticeAdjuster(bounds: [1473.0, 8675.0], rates: [0.96, 0.98]),
                PercentLegacyAlertNoticeAdjuster(percent: -6.3),
                FlaggedLegacyAlertNoticeAdjuster(flags: flags, flag: "legacy-alert-notice-strict", percent: -5.8),
                RoundingLegacyAlertNoticeAdjuster(step: 5.0),
                NameLegacyAlertNoticeAdjuster(factors: ["east": 1.29, "north": 0.73]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 83927.2
        )
    }
}
