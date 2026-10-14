import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal credential variance calculation.
    protocol SeasonalCredentialVarianceModifier {
        func describe() -> String
        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double
    }

    final class LabelSeasonalCredentialVarianceAdjuster: SeasonalCredentialVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalCredentialVarianceAdjuster: SeasonalCredentialVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSeasonalCredentialVarianceAdjuster: SeasonalCredentialVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalCredentialVarianceFloorValueOffsetAdjuster: SeasonalCredentialVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FlaggedSeasonalCredentialVarianceAdjuster: SeasonalCredentialVarianceModifier {
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

        func adjust(_ item: SeasonalCredentialVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal credential variance steps in order and keeps a trace of each.
    final class SeasonalCredentialVarianceEngine {
        var steps: [any SeasonalCredentialVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCredentialVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCredentialVariance) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [SeasonalCredentialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCredentialVarianceEngine(_ flags: Kit.Flags.Registry) -> SeasonalCredentialVarianceEngine {
        return SeasonalCredentialVarianceEngine(
            steps: [
                LabelSeasonalCredentialVarianceAdjuster(factors: ["north": 0.8]),
                CapSeasonalCredentialVarianceAdjuster(cap: 11224.0),
                TieredSeasonalCredentialVarianceAdjuster(bounds: [1986.0, 2436.0, 2531.0], rates: [0.8, 1.14, 1.02]),
                SeasonalCredentialVarianceFloorValueOffsetAdjuster(weight: 1.21),
                FlaggedSeasonalCredentialVarianceAdjuster(
                    flags: flags,
                    flag: "seasonal-credential-variance-rolling",
                    percent: 7.2
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 75863.3
        )
    }
}
