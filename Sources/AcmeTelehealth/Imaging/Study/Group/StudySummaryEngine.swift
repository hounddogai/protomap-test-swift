import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study summary calculation.
    protocol StudySummaryAdjuster {
        func describe() -> String
        func adjust(_ item: StudySummary, value: Double) -> Double
    }

    final class ChannelStudySummaryAdjuster: StudySummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StudySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStudySummaryAdjuster: StudySummaryAdjuster {
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

        func adjust(_ item: StudySummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StudySummaryCeilingOffsetAdjuster: StudySummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: StudySummary, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class PercentStudySummaryAdjuster: StudySummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStudySummaryAdjuster: StudySummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study summary steps in order and keeps a trace of each.
    final class StudySummaryEngine {
        var steps: [any StudySummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudySummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StudySummary) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StudySummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [StudySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStudySummaryEngine(_ flags: Kit.Flags.Registry) -> StudySummaryEngine {
        return StudySummaryEngine(
            steps: [
                ChannelStudySummaryAdjuster(factors: ["west": 1.34]),
                FlaggedStudySummaryAdjuster(flags: flags, flag: "study-summary-scheduled", percent: -8.1),
                StudySummaryCeilingOffsetAdjuster(weight: 1.15),
                PercentStudySummaryAdjuster(percent: -3.0),
                RoundingStudySummaryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 99465.2
        )
    }
}
