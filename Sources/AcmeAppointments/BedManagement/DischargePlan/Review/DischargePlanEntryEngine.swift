import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan entry calculation.
    protocol DischargePlanEntryStep {
        func describe() -> String
        func adjust(_ item: DischargePlanEntry, value: Double) -> Double
    }

    final class LabelDischargePlanEntryAdjuster: DischargePlanEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DischargePlanEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDischargePlanEntryAdjuster: DischargePlanEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDischargePlanEntryAdjuster: DischargePlanEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDischargePlanEntryAdjuster: DischargePlanEntryStep {
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

        func adjust(_ item: DischargePlanEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDischargePlanEntryAdjuster: DischargePlanEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the discharge plan entry steps in order and keeps a trace of each.
    final class DischargePlanEntryEngine {
        var steps: [any DischargePlanEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DischargePlanEntry) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanEntryStep = steps[index]
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

        func evaluateAll(_ items: [DischargePlanEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDischargePlanEntryEngine(_ flags: Kit.Flags.Registry) -> DischargePlanEntryEngine {
        return DischargePlanEntryEngine(
            steps: [
                LabelDischargePlanEntryAdjuster(factors: ["east": 0.93, "central": 1.17]),
                PercentDischargePlanEntryAdjuster(percent: 9.3),
                MinimumDischargePlanEntryAdjuster(minimum: 37.2),
                FlaggedDischargePlanEntryAdjuster(flags: flags, flag: "discharge-plan-entry-default", percent: 9.1),
                RoundingDischargePlanEntryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 33753.9
        )
    }
}
