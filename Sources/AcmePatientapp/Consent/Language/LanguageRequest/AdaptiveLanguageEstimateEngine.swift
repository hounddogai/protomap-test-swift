import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive language estimate calculation.
    protocol AdaptiveLanguageEstimateStep {
        func describe() -> String
        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double
    }

    final class PercentAdaptiveLanguageEstimateAdjuster: AdaptiveLanguageEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAdaptiveLanguageEstimateAdjuster: AdaptiveLanguageEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveLanguageEstimateAdjuster: AdaptiveLanguageEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveLanguageEstimateAdjuster: AdaptiveLanguageEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveLanguageEstimateUpdatedAtOffsetAdjuster: AdaptiveLanguageEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class FlaggedAdaptiveLanguageEstimateAdjuster: AdaptiveLanguageEstimateStep {
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

        func adjust(_ item: AdaptiveLanguageEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive language estimate steps in order and keeps a trace of each.
    final class AdaptiveLanguageEstimateEngine {
        var steps: [any AdaptiveLanguageEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveLanguageEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveLanguageEstimate) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [AdaptiveLanguageEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveLanguageEstimateEngine(_ flags: Kit.Flags.Registry) -> AdaptiveLanguageEstimateEngine {
        return AdaptiveLanguageEstimateEngine(
            steps: [
                PercentAdaptiveLanguageEstimateAdjuster(percent: -13.6),
                LabelAdaptiveLanguageEstimateAdjuster(factors: ["north": 0.98, "central": 1.37, "east": 0.89]),
                TieredAdaptiveLanguageEstimateAdjuster(bounds: [4524.0, 5699.0], rates: [0.98, 0.87]),
                MinimumAdaptiveLanguageEstimateAdjuster(minimum: 30.3),
                AdaptiveLanguageEstimateUpdatedAtOffsetAdjuster(weight: 0.63),
                FlaggedAdaptiveLanguageEstimateAdjuster(
                    flags: flags,
                    flag: "adaptive-language-estimate-manual",
                    percent: -6.4
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 88721.1
        )
    }
}
