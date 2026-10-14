import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge notice calculation.
    protocol ChargeNoticeModifier {
        func describe() -> String
        func adjust(_ item: ChargeNotice, value: Double) -> Double
    }

    final class MinimumChargeNoticeAdjuster: ChargeNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedChargeNoticeAdjuster: ChargeNoticeModifier {
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

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentChargeNoticeAdjuster: ChargeNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingChargeNoticeAdjuster: ChargeNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapChargeNoticeAdjuster: ChargeNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityChargeNoticeAdjuster: ChargeNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ChargeNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the charge notice steps in order and keeps a trace of each.
    final class ChargeNoticeEngine {
        var steps: [any ChargeNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeNotice) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeNoticeEngine(_ flags: Kit.Flags.Registry) -> ChargeNoticeEngine {
        return ChargeNoticeEngine(
            steps: [
                MinimumChargeNoticeAdjuster(minimum: 3.2),
                FlaggedChargeNoticeAdjuster(flags: flags, flag: "charge-notice-default", percent: 9.5),
                PercentChargeNoticeAdjuster(percent: -18.0),
                RoundingChargeNoticeAdjuster(step: 1.0),
                CapChargeNoticeAdjuster(cap: 33575.0),
                FacilityChargeNoticeAdjuster(factors: ["west": 1.0, "central": 0.76, "south": 1.22]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 10419.0
        )
    }
}
