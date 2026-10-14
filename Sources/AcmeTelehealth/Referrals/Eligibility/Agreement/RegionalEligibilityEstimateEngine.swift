import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional eligibility estimate calculation.
    protocol RegionalEligibilityEstimateModifier {
        func describe() -> String
        func adjust(_ item: RegionalEligibilityEstimate, value: Double) -> Double
    }

    final class PercentRegionalEligibilityEstimateAdjuster: RegionalEligibilityEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalEligibilityEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRegionalEligibilityEstimateAdjuster: RegionalEligibilityEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalEligibilityEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalEligibilityEstimateAdjuster: RegionalEligibilityEstimateModifier {
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

        func adjust(_ item: RegionalEligibilityEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional eligibility estimate steps in order and keeps a trace of each.
    final class RegionalEligibilityEstimateEngine {
        var steps: [any RegionalEligibilityEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalEligibilityEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalEligibilityEstimate) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalEligibilityEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalEligibilityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalEligibilityEstimateEngine(_ flags: Kit.Flags.Registry) -> RegionalEligibilityEstimateEngine {
        return RegionalEligibilityEstimateEngine(
            steps: [
                PercentRegionalEligibilityEstimateAdjuster(percent: 13.1),
                TitleRegionalEligibilityEstimateAdjuster(factors: ["south": 0.75, "west": 1.18]),
                FlaggedRegionalEligibilityEstimateAdjuster(
                    flags: flags,
                    flag: "regional-eligibility-estimate-manual",
                    percent: 0.1
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 60239.7
        )
    }
}
