import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap summary calculation.
    protocol CareGapSummaryFactor {
        func describe() -> String
        func adjust(_ item: CareGapSummary, value: Double) -> Double
    }

    final class FlaggedCareGapSummaryAdjuster: CareGapSummaryFactor {
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

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCareGapSummaryAdjuster: CareGapSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareGapSummaryAdjuster: CareGapSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCareGapSummaryAdjuster: CareGapSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCareGapSummaryAdjuster: CareGapSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapSummaryAdjuster: CareGapSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap summary steps in order and keeps a trace of each.
    final class CareGapSummaryEngine {
        var steps: [any CareGapSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapSummary) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapSummaryEngine(_ flags: Kit.Flags.Registry) -> CareGapSummaryEngine {
        return CareGapSummaryEngine(
            steps: [
                FlaggedCareGapSummaryAdjuster(flags: flags, flag: "care-gap-summary-pending", percent: -4.5),
                TitleCareGapSummaryAdjuster(factors: ["north": 1.19, "east": 1.1]),
                RoundingCareGapSummaryAdjuster(step: 0.05),
                MinimumCareGapSummaryAdjuster(minimum: 5.4),
                CapCareGapSummaryAdjuster(cap: 25063.0),
                PercentCareGapSummaryAdjuster(percent: 2.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 7222.1
        )
    }
}
