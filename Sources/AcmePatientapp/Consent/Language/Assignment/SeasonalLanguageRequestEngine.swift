import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal language request calculation.
    protocol SeasonalLanguageRequestAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double
    }

    final class FlaggedSeasonalLanguageRequestAdjuster: SeasonalLanguageRequestAdjuster {
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

        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalLanguageRequestAdjuster: SeasonalLanguageRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSeasonalLanguageRequestAdjuster: SeasonalLanguageRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameSeasonalLanguageRequestAdjuster: SeasonalLanguageRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalLanguageRequestAdjuster: SeasonalLanguageRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalLanguageRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal language request steps in order and keeps a trace of each.
    final class SeasonalLanguageRequestEngine {
        var steps: [any SeasonalLanguageRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalLanguageRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalLanguageRequest) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [SeasonalLanguageRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalLanguageRequestEngine(_ flags: Kit.Flags.Registry) -> SeasonalLanguageRequestEngine {
        return SeasonalLanguageRequestEngine(
            steps: [
                FlaggedSeasonalLanguageRequestAdjuster(
                    flags: flags,
                    flag: "seasonal-language-request-lenient",
                    percent: 7.5
                ),
                RoundingSeasonalLanguageRequestAdjuster(step: 0.5),
                TieredSeasonalLanguageRequestAdjuster(bounds: [2227.0, 2510.0], rates: [1.06, 0.92]),
                NameSeasonalLanguageRequestAdjuster(factors: ["online": 0.87]),
                MinimumSeasonalLanguageRequestAdjuster(minimum: 39.9),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 30956.8
        )
    }
}
