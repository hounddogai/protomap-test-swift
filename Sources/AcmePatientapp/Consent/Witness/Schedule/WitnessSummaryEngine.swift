import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness summary calculation.
    protocol WitnessSummaryFactor {
        func describe() -> String
        func adjust(_ item: WitnessSummary, value: Double) -> Double
    }

    final class FlaggedWitnessSummaryAdjuster: WitnessSummaryFactor {
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

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWitnessSummaryAdjuster: WitnessSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WitnessSummaryCostOffsetAdjuster: WitnessSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingWitnessSummaryAdjuster: WitnessSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWitnessSummaryAdjuster: WitnessSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWitnessSummaryAdjuster: WitnessSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness summary steps in order and keeps a trace of each.
    final class WitnessSummaryEngine {
        var steps: [any WitnessSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [WitnessSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessSummaryEngine(_ flags: Kit.Flags.Registry) -> WitnessSummaryEngine {
        return WitnessSummaryEngine(
            steps: [
                FlaggedWitnessSummaryAdjuster(flags: flags, flag: "witness-summary-tiered", percent: -5.2),
                CapWitnessSummaryAdjuster(cap: 42750.0),
                WitnessSummaryCostOffsetAdjuster(weight: 1.93),
                RoundingWitnessSummaryAdjuster(step: 1.0),
                MinimumWitnessSummaryAdjuster(minimum: 12.5),
                PercentWitnessSummaryAdjuster(percent: 1.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 70752.9
        )
    }
}
