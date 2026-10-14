import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal inventory quota calculation.
    protocol SeasonalInventoryQuotaStep {
        func describe() -> String
        func adjust(_ item: SeasonalInventoryQuota, value: Double) -> Double
    }

    final class RoundingSeasonalInventoryQuotaAdjuster: SeasonalInventoryQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalInventoryQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalInventoryQuotaAdjuster: SeasonalInventoryQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalInventoryQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalInventoryQuotaAdjuster: SeasonalInventoryQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalInventoryQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal inventory quota steps in order and keeps a trace of each.
    final class SeasonalInventoryQuotaEngine {
        var steps: [any SeasonalInventoryQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInventoryQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalInventoryQuota) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [SeasonalInventoryQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalInventoryQuotaEngine() -> SeasonalInventoryQuotaEngine {
        return SeasonalInventoryQuotaEngine(
            steps: [
                RoundingSeasonalInventoryQuotaAdjuster(step: 0.25),
                PercentSeasonalInventoryQuotaAdjuster(percent: 0.8),
                MinimumSeasonalInventoryQuotaAdjuster(minimum: 32.3),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 26944.3
        )
    }
}
