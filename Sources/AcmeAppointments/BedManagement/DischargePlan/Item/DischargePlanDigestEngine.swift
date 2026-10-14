import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan digest calculation.
    protocol DischargePlanDigestModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanDigest, value: Double) -> Double
    }

    final class TitleDischargePlanDigestAdjuster: DischargePlanDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DischargePlanDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDischargePlanDigestAdjuster: DischargePlanDigestModifier {
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

        func adjust(_ item: DischargePlanDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDischargePlanDigestAdjuster: DischargePlanDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDischargePlanDigestAdjuster: DischargePlanDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DischargePlanDigestMarginOffsetAdjuster: DischargePlanDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: DischargePlanDigest, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the discharge plan digest steps in order and keeps a trace of each.
    final class DischargePlanDigestEngine {
        var steps: [any DischargePlanDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanDigest) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanDigestModifier = steps[index]
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

        func evaluateAll(_ items: [DischargePlanDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanDigestEngine(_ flags: Kit.Flags.Registry) -> DischargePlanDigestEngine {
        return DischargePlanDigestEngine(
            steps: [
                TitleDischargePlanDigestAdjuster(factors: ["east": 1.2, "retail": 1.19]),
                FlaggedDischargePlanDigestAdjuster(flags: flags, flag: "discharge-plan-digest-global", percent: 2.7),
                RoundingDischargePlanDigestAdjuster(step: 1.0),
                CapDischargePlanDigestAdjuster(cap: 31821.0),
                DischargePlanDigestMarginOffsetAdjuster(weight: 1.81),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 97834.4
        )
    }
}
