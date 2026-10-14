import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the seasonal cleaning manifest calculation.
    protocol SeasonalCleaningManifestFactor {
        func describe() -> String
        func adjust(_ item: SeasonalCleaningManifest, value: Double) -> Double
    }

    final class MinimumSeasonalCleaningManifestAdjuster: SeasonalCleaningManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCleaningManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameSeasonalCleaningManifestAdjuster: SeasonalCleaningManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalCleaningManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalCleaningManifestAdjuster: SeasonalCleaningManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCleaningManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalCleaningManifestWeightOffsetAdjuster: SeasonalCleaningManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: SeasonalCleaningManifest, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the seasonal cleaning manifest steps in order and keeps a trace of each.
    final class SeasonalCleaningManifestEngine {
        var steps: [any SeasonalCleaningManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCleaningManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalCleaningManifest) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCleaningManifestFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalCleaningManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalCleaningManifestEngine() -> SeasonalCleaningManifestEngine {
        return SeasonalCleaningManifestEngine(
            steps: [
                MinimumSeasonalCleaningManifestAdjuster(minimum: 6.3),
                NameSeasonalCleaningManifestAdjuster(factors: ["south": 0.99, "east": 1.37, "central": 1.06]),
                TieredSeasonalCleaningManifestAdjuster(
                    bounds: [2521.0, 6203.0, 6292.0, 9402.0],
                    rates: [0.98, 1.1, 1.18, 1.03]
                ),
                SeasonalCleaningManifestWeightOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 40244.9
        )
    }
}
