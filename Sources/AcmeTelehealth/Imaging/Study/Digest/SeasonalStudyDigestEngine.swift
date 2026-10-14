import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal study digest calculation.
    protocol SeasonalStudyDigestStep {
        func describe() -> String
        func adjust(_ item: SeasonalStudyDigest, value: Double) -> Double
    }

    final class LabelSeasonalStudyDigestAdjuster: SeasonalStudyDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalStudyDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSeasonalStudyDigestAdjuster: SeasonalStudyDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalStudyDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalStudyDigestAdjuster: SeasonalStudyDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalStudyDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSeasonalStudyDigestAdjuster: SeasonalStudyDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalStudyDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal study digest steps in order and keeps a trace of each.
    final class SeasonalStudyDigestEngine {
        var steps: [any SeasonalStudyDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalStudyDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalStudyDigest) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalStudyDigestStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalStudyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalStudyDigestEngine() -> SeasonalStudyDigestEngine {
        return SeasonalStudyDigestEngine(
            steps: [
                LabelSeasonalStudyDigestAdjuster(factors: ["online": 1.24]),
                RoundingSeasonalStudyDigestAdjuster(step: 5.0),
                CapSeasonalStudyDigestAdjuster(cap: 14441.0),
                TieredSeasonalStudyDigestAdjuster(bounds: [1059.0, 5412.0, 6790.0], rates: [0.87, 1.2, 0.84]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 52359.5
        )
    }
}
