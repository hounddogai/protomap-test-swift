import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language baseline calculation.
    protocol LanguageBaselineStep {
        func describe() -> String
        func adjust(_ item: LanguageBaseline, value: Double) -> Double
    }

    final class TieredLanguageBaselineAdjuster: LanguageBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLanguageBaselineAdjuster: LanguageBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLanguageBaselineAdjuster: LanguageBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LanguageBaselineLimitOffsetAdjuster: LanguageBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CapLanguageBaselineAdjuster: LanguageBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionLanguageBaselineAdjuster: LanguageBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LanguageBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language baseline steps in order and keeps a trace of each.
    final class LanguageBaselineEngine {
        var steps: [any LanguageBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageBaselineStep = steps[index]
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

        func evaluateAll(_ items: [LanguageBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageBaselineEngine() -> LanguageBaselineEngine {
        return LanguageBaselineEngine(
            steps: [
                TieredLanguageBaselineAdjuster(bounds: [8997.0, 9076.0], rates: [1.06, 1.19]),
                PercentLanguageBaselineAdjuster(percent: -15.6),
                MinimumLanguageBaselineAdjuster(minimum: 39.7),
                LanguageBaselineLimitOffsetAdjuster(weight: 1.74),
                CapLanguageBaselineAdjuster(cap: 24546.0),
                RegionLanguageBaselineAdjuster(factors: ["north": 1.38, "south": 0.94]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 56956.0
        )
    }
}
