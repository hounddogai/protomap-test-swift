import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional care gap summary calculation.
    protocol RegionalCareGapSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalCareGapSummary, value: Double) -> Double
    }

    final class MinimumRegionalCareGapSummaryAdjuster: RegionalCareGapSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCareGapSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalCareGapSummaryAdjuster: RegionalCareGapSummaryAdjuster {
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

        func adjust(_ item: RegionalCareGapSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalCareGapSummaryThresholdOffsetAdjuster: RegionalCareGapSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: RegionalCareGapSummary, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the regional care gap summary steps in order and keeps a trace of each.
    final class RegionalCareGapSummaryEngine {
        var steps: [any RegionalCareGapSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareGapSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalCareGapSummary) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalCareGapSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalCareGapSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalCareGapSummaryEngine(_ flags: Kit.Flags.Registry) -> RegionalCareGapSummaryEngine {
        return RegionalCareGapSummaryEngine(
            steps: [
                MinimumRegionalCareGapSummaryAdjuster(minimum: 1.6),
                FlaggedRegionalCareGapSummaryAdjuster(
                    flags: flags,
                    flag: "regional-care-gap-summary-scheduled",
                    percent: 1.6
                ),
                RegionalCareGapSummaryThresholdOffsetAdjuster(weight: 0.55),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 59515.8
        )
    }
}
