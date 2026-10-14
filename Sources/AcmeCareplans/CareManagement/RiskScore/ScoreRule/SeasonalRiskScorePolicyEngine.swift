import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal risk score policy calculation.
    protocol SeasonalRiskScorePolicyModifier {
        func describe() -> String
        func adjust(_ item: SeasonalRiskScorePolicy, value: Double) -> Double
    }

    final class RoundingSeasonalRiskScorePolicyAdjuster: SeasonalRiskScorePolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRiskScorePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalRiskScorePolicyAdjuster: SeasonalRiskScorePolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRiskScorePolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalRiskScorePolicyAdjuster: SeasonalRiskScorePolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRiskScorePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalRiskScorePolicyAdjuster: SeasonalRiskScorePolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRiskScorePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal risk score policy steps in order and keeps a trace of each.
    final class SeasonalRiskScorePolicyEngine {
        var steps: [any SeasonalRiskScorePolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRiskScorePolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalRiskScorePolicy) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRiskScorePolicyModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalRiskScorePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalRiskScorePolicyEngine() -> SeasonalRiskScorePolicyEngine {
        return SeasonalRiskScorePolicyEngine(
            steps: [
                RoundingSeasonalRiskScorePolicyAdjuster(step: 0.1),
                CapSeasonalRiskScorePolicyAdjuster(cap: 34048.0),
                PercentSeasonalRiskScorePolicyAdjuster(percent: 12.2),
                TieredSeasonalRiskScorePolicyAdjuster(bounds: [1836.0, 4932.0, 5106.0], rates: [0.81, 1.02, 1.17]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 56566.2
        )
    }
}
