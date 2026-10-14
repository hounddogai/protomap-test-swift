import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional risk score summary calculation.
    protocol RegionalRiskScoreSummaryModifier {
        func describe() -> String
        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double
    }

    final class PercentRegionalRiskScoreSummaryAdjuster: RegionalRiskScoreSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalRiskScoreSummaryAdjuster: RegionalRiskScoreSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalRiskScoreSummaryCapacityOffsetAdjuster: RegionalRiskScoreSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedRegionalRiskScoreSummaryAdjuster: RegionalRiskScoreSummaryModifier {
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

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalRiskScoreSummaryAdjuster: RegionalRiskScoreSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalRiskScoreSummaryAdjuster: RegionalRiskScoreSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRiskScoreSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional risk score summary steps in order and keeps a trace of each.
    final class RegionalRiskScoreSummaryEngine {
        var steps: [any RegionalRiskScoreSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRiskScoreSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalRiskScoreSummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalRiskScoreSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalRiskScoreSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalRiskScoreSummaryEngine(_ flags: Kit.Flags.Registry) -> RegionalRiskScoreSummaryEngine {
        return RegionalRiskScoreSummaryEngine(
            steps: [
                PercentRegionalRiskScoreSummaryAdjuster(percent: -8.9),
                CapRegionalRiskScoreSummaryAdjuster(cap: 24428.0),
                RegionalRiskScoreSummaryCapacityOffsetAdjuster(weight: 0.86),
                FlaggedRegionalRiskScoreSummaryAdjuster(
                    flags: flags,
                    flag: "regional-risk-score-summary-manual",
                    percent: -8.9
                ),
                RoundingRegionalRiskScoreSummaryAdjuster(step: 0.1),
                MinimumRegionalRiskScoreSummaryAdjuster(minimum: 6.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 95185.0
        )
    }
}
