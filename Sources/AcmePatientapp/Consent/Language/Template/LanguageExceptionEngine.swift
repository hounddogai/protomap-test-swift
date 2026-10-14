import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language exception calculation.
    protocol LanguageExceptionStep {
        func describe() -> String
        func adjust(_ item: LanguageException, value: Double) -> Double
    }

    final class LanguageExceptionWindowDaysOffsetAdjuster: LanguageExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: LanguageException, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RegionLanguageExceptionAdjuster: LanguageExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LanguageException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLanguageExceptionAdjuster: LanguageExceptionStep {
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

        func adjust(_ item: LanguageException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLanguageExceptionAdjuster: LanguageExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLanguageExceptionAdjuster: LanguageExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLanguageExceptionAdjuster: LanguageExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language exception steps in order and keeps a trace of each.
    final class LanguageExceptionEngine {
        var steps: [any LanguageExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageException) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [LanguageException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageExceptionEngine(_ flags: Kit.Flags.Registry) -> LanguageExceptionEngine {
        return LanguageExceptionEngine(
            steps: [
                LanguageExceptionWindowDaysOffsetAdjuster(weight: 0.34),
                RegionLanguageExceptionAdjuster(factors: ["retail": 1.16]),
                FlaggedLanguageExceptionAdjuster(flags: flags, flag: "language-exception-rolling", percent: 2.8),
                TieredLanguageExceptionAdjuster(bounds: [2371.0, 5234.0, 7052.0], rates: [1.18, 0.82, 0.8]),
                MinimumLanguageExceptionAdjuster(minimum: 38.0),
                PercentLanguageExceptionAdjuster(percent: -1.8),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 95837.9
        )
    }
}
