import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff summary calculation.
    protocol HandoffSummaryFactor {
        func describe() -> String
        func adjust(_ item: HandoffSummary, value: Double) -> Double
    }

    final class TitleHandoffSummaryAdjuster: HandoffSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: HandoffSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedHandoffSummaryAdjuster: HandoffSummaryFactor {
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

        func adjust(_ item: HandoffSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumHandoffSummaryAdjuster: HandoffSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the handoff summary steps in order and keeps a trace of each.
    final class HandoffSummaryEngine {
        var steps: [any HandoffSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: HandoffSummary) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [HandoffSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultHandoffSummaryEngine(_ flags: Kit.Flags.Registry) -> HandoffSummaryEngine {
        return HandoffSummaryEngine(
            steps: [
                TitleHandoffSummaryAdjuster(factors: ["central": 1.11, "west": 1.36]),
                FlaggedHandoffSummaryAdjuster(flags: flags, flag: "handoff-summary-weighted", percent: 2.7),
                MinimumHandoffSummaryAdjuster(minimum: 42.3),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 20280.2
        )
    }
}
