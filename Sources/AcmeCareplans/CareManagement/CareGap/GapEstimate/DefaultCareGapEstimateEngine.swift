import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default care gap estimate calculation.
    protocol DefaultCareGapEstimateStep {
        func describe() -> String
        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double
    }

    final class FlaggedDefaultCareGapEstimateAdjuster: DefaultCareGapEstimateStep {
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

        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleDefaultCareGapEstimateAdjuster: DefaultCareGapEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultCareGapEstimateCapacityOffsetAdjuster: DefaultCareGapEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumDefaultCareGapEstimateAdjuster: DefaultCareGapEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultCareGapEstimateAdjuster: DefaultCareGapEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareGapEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default care gap estimate steps in order and keeps a trace of each.
    final class DefaultCareGapEstimateEngine {
        var steps: [any DefaultCareGapEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareGapEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultCareGapEstimate) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [DefaultCareGapEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultCareGapEstimateEngine(_ flags: Kit.Flags.Registry) -> DefaultCareGapEstimateEngine {
        return DefaultCareGapEstimateEngine(
            steps: [
                FlaggedDefaultCareGapEstimateAdjuster(
                    flags: flags,
                    flag: "default-care-gap-estimate-manual",
                    percent: -4.9
                ),
                TitleDefaultCareGapEstimateAdjuster(factors: ["north": 1.27, "central": 1.24, "east": 1.25]),
                DefaultCareGapEstimateCapacityOffsetAdjuster(weight: 1.56),
                MinimumDefaultCareGapEstimateAdjuster(minimum: 24.2),
                TieredDefaultCareGapEstimateAdjuster(bounds: [7864.0, 7988.0, 9671.0], rates: [0.81, 1.02, 1.19]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 90818.5
        )
    }
}
