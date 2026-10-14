import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal read milestone calculation.
    protocol SeasonalReadMilestoneFactor {
        func describe() -> String
        func adjust(_ item: SeasonalReadMilestone, value: Double) -> Double
    }

    final class CountrySeasonalReadMilestoneAdjuster: SeasonalReadMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: SeasonalReadMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalReadMilestoneAdjuster: SeasonalReadMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalReadMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalReadMilestoneCreatedAtOffsetAdjuster: SeasonalReadMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: SeasonalReadMilestone, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumSeasonalReadMilestoneAdjuster: SeasonalReadMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalReadMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal read milestone steps in order and keeps a trace of each.
    final class SeasonalReadMilestoneEngine {
        var steps: [any SeasonalReadMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReadMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalReadMilestone) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [SeasonalReadMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalReadMilestoneEngine() -> SeasonalReadMilestoneEngine {
        return SeasonalReadMilestoneEngine(
            steps: [
                CountrySeasonalReadMilestoneAdjuster(factors: ["online": 1.15, "west": 1.08, "north": 1.23]),
                TieredSeasonalReadMilestoneAdjuster(bounds: [949.0, 4403.0, 5487.0], rates: [0.87, 0.84, 0.92]),
                SeasonalReadMilestoneCreatedAtOffsetAdjuster(weight: 1.52),
                MinimumSeasonalReadMilestoneAdjuster(minimum: 0.8),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 49189.4
        )
    }
}
