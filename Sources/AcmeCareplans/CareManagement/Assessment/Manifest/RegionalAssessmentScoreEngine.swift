import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional assessment score calculation.
    protocol RegionalAssessmentScoreFactor {
        func describe() -> String
        func adjust(_ item: RegionalAssessmentScore, value: Double) -> Double
    }

    final class MinimumRegionalAssessmentScoreAdjuster: RegionalAssessmentScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAssessmentScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalAssessmentScoreAdjuster: RegionalAssessmentScoreFactor {
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

        func adjust(_ item: RegionalAssessmentScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalAssessmentScoreAdjuster: RegionalAssessmentScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalAssessmentScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional assessment score steps in order and keeps a trace of each.
    final class RegionalAssessmentScoreEngine {
        var steps: [any RegionalAssessmentScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAssessmentScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalAssessmentScore) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAssessmentScoreFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalAssessmentScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalAssessmentScoreEngine(_ flags: Kit.Flags.Registry) -> RegionalAssessmentScoreEngine {
        return RegionalAssessmentScoreEngine(
            steps: [
                MinimumRegionalAssessmentScoreAdjuster(minimum: 17.8),
                FlaggedRegionalAssessmentScoreAdjuster(
                    flags: flags,
                    flag: "regional-assessment-score-pending",
                    percent: 9.3
                ),
                TieredRegionalAssessmentScoreAdjuster(bounds: [3970.0, 4148.0, 7025.0], rates: [1.06, 1.1, 1.11]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 73452.5
        )
    }
}
