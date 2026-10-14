import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal specimen quota calculation.
    protocol SeasonalSpecimenQuotaFactor {
        func describe() -> String
        func adjust(_ item: SeasonalSpecimenQuota, value: Double) -> Double
    }

    final class MinimumSeasonalSpecimenQuotaAdjuster: SeasonalSpecimenQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSpecimenQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSeasonalSpecimenQuotaAdjuster: SeasonalSpecimenQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSpecimenQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalSpecimenQuotaAdjuster: SeasonalSpecimenQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSpecimenQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SeasonalSpecimenQuotaLimitOffsetAdjuster: SeasonalSpecimenQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: SeasonalSpecimenQuota, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the seasonal specimen quota steps in order and keeps a trace of each.
    final class SeasonalSpecimenQuotaEngine {
        var steps: [any SeasonalSpecimenQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSpecimenQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalSpecimenQuota) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [SeasonalSpecimenQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalSpecimenQuotaEngine() -> SeasonalSpecimenQuotaEngine {
        return SeasonalSpecimenQuotaEngine(
            steps: [
                MinimumSeasonalSpecimenQuotaAdjuster(minimum: 12.6),
                PercentSeasonalSpecimenQuotaAdjuster(percent: 14.2),
                RoundingSeasonalSpecimenQuotaAdjuster(step: 0.25),
                SeasonalSpecimenQuotaLimitOffsetAdjuster(weight: 0.2),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 3143.9
        )
    }
}
