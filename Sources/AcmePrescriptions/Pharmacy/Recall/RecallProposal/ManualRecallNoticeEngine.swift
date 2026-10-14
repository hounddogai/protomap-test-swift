import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual recall notice calculation.
    protocol ManualRecallNoticeModifier {
        func describe() -> String
        func adjust(_ item: ManualRecallNotice, value: Double) -> Double
    }

    final class TieredManualRecallNoticeAdjuster: ManualRecallNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRecallNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualRecallNoticeAdjuster: ManualRecallNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRecallNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleManualRecallNoticeAdjuster: ManualRecallNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualRecallNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualRecallNoticeAmountOffsetAdjuster: ManualRecallNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ManualRecallNotice, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedManualRecallNoticeAdjuster: ManualRecallNoticeModifier {
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

        func adjust(_ item: ManualRecallNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual recall notice steps in order and keeps a trace of each.
    final class ManualRecallNoticeEngine {
        var steps: [any ManualRecallNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRecallNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRecallNotice) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRecallNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [ManualRecallNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRecallNoticeEngine(_ flags: Kit.Flags.Registry) -> ManualRecallNoticeEngine {
        return ManualRecallNoticeEngine(
            steps: [
                TieredManualRecallNoticeAdjuster(bounds: [3890.0, 3908.0], rates: [0.88, 0.9]),
                MinimumManualRecallNoticeAdjuster(minimum: 21.7),
                LocaleManualRecallNoticeAdjuster(factors: ["north": 1.03, "retail": 0.92, "south": 1.08]),
                ManualRecallNoticeAmountOffsetAdjuster(weight: 1.54),
                FlaggedManualRecallNoticeAdjuster(flags: flags, flag: "manual-recall-notice-capped", percent: 2.4),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 30150.4
        )
    }
}
