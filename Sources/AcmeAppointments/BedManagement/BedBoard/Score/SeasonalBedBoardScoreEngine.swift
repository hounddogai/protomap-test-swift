import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the seasonal bed board score calculation.
    protocol SeasonalBedBoardScoreAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double
    }

    final class TitleSeasonalBedBoardScoreAdjuster: SeasonalBedBoardScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalBedBoardScoreAdjuster: SeasonalBedBoardScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalBedBoardScoreAdjuster: SeasonalBedBoardScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalBedBoardScoreAdjuster: SeasonalBedBoardScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalBedBoardScoreAdjuster: SeasonalBedBoardScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalBedBoardScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal bed board score steps in order and keeps a trace of each.
    final class SeasonalBedBoardScoreEngine {
        var steps: [any SeasonalBedBoardScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalBedBoardScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalBedBoardScore) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalBedBoardScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalBedBoardScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalBedBoardScoreEngine() -> SeasonalBedBoardScoreEngine {
        return SeasonalBedBoardScoreEngine(
            steps: [
                TitleSeasonalBedBoardScoreAdjuster(factors: ["online": 0.71, "south": 1.28]),
                CapSeasonalBedBoardScoreAdjuster(cap: 24229.0),
                PercentSeasonalBedBoardScoreAdjuster(percent: -10.5),
                TieredSeasonalBedBoardScoreAdjuster(
                    bounds: [2790.0, 6101.0, 6379.0, 7267.0],
                    rates: [1.0, 1.07, 0.86, 0.9]
                ),
                RoundingSeasonalBedBoardScoreAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 54711.1
        )
    }
}
