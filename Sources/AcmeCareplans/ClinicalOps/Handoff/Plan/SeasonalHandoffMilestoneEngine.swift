import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal handoff milestone calculation.
    protocol SeasonalHandoffMilestoneFactor {
        func describe() -> String
        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double
    }

    final class MinimumSeasonalHandoffMilestoneAdjuster: SeasonalHandoffMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSeasonalHandoffMilestoneAdjuster: SeasonalHandoffMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalHandoffMilestoneAdjuster: SeasonalHandoffMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalHandoffMilestoneScoreOffsetAdjuster: SeasonalHandoffMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class LabelSeasonalHandoffMilestoneAdjuster: SeasonalHandoffMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalHandoffMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal handoff milestone steps in order and keeps a trace of each.
    final class SeasonalHandoffMilestoneEngine {
        var steps: [any SeasonalHandoffMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalHandoffMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalHandoffMilestone) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalHandoffMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalHandoffMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalHandoffMilestoneEngine() -> SeasonalHandoffMilestoneEngine {
        return SeasonalHandoffMilestoneEngine(
            steps: [
                MinimumSeasonalHandoffMilestoneAdjuster(minimum: 28.5),
                PercentSeasonalHandoffMilestoneAdjuster(percent: 19.0),
                TieredSeasonalHandoffMilestoneAdjuster(bounds: [5018.0, 5415.0, 9055.0], rates: [1.15, 0.91, 0.95]),
                SeasonalHandoffMilestoneScoreOffsetAdjuster(weight: 1.97),
                LabelSeasonalHandoffMilestoneAdjuster(factors: ["west": 0.72, "online": 1.39, "central": 0.96]),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 71569.3
        )
    }
}
