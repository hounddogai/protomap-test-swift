import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal program group calculation.
    protocol SeasonalProgramGroupStep {
        func describe() -> String
        func adjust(_ item: SeasonalProgramGroup, value: Double) -> Double
    }

    final class SeasonalProgramGroupGraceDaysOffsetAdjuster: SeasonalProgramGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: SeasonalProgramGroup, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class NameSeasonalProgramGroupAdjuster: SeasonalProgramGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalProgramGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalProgramGroupAdjuster: SeasonalProgramGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalProgramGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalProgramGroupAdjuster: SeasonalProgramGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalProgramGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal program group steps in order and keeps a trace of each.
    final class SeasonalProgramGroupEngine {
        var steps: [any SeasonalProgramGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalProgramGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalProgramGroup) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [SeasonalProgramGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalProgramGroupEngine() -> SeasonalProgramGroupEngine {
        return SeasonalProgramGroupEngine(
            steps: [
                SeasonalProgramGroupGraceDaysOffsetAdjuster(weight: 0.41),
                NameSeasonalProgramGroupAdjuster(factors: ["online": 1.34, "central": 0.92]),
                PercentSeasonalProgramGroupAdjuster(percent: 10.4),
                TieredSeasonalProgramGroupAdjuster(bounds: [4201.0, 4396.0], rates: [1.07, 0.91]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 99522.7
        )
    }
}
