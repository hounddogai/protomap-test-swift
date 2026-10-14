import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal modality quota calculation.
    protocol SeasonalModalityQuotaModifier {
        func describe() -> String
        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double
    }

    final class FlaggedSeasonalModalityQuotaAdjuster: SeasonalModalityQuotaModifier {
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

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalModalityQuotaAdjuster: SeasonalModalityQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalModalityQuotaAdjuster: SeasonalModalityQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SeasonalModalityQuotaAcuityOffsetAdjuster: SeasonalModalityQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredSeasonalModalityQuotaAdjuster: SeasonalModalityQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSeasonalModalityQuotaAdjuster: SeasonalModalityQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalModalityQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal modality quota steps in order and keeps a trace of each.
    final class SeasonalModalityQuotaEngine {
        var steps: [any SeasonalModalityQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalModalityQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalModalityQuota) -> Double {
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

        func evaluateAll(_ items: [SeasonalModalityQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalModalityQuotaEngine(_ flags: Kit.Flags.Registry) -> SeasonalModalityQuotaEngine {
        return SeasonalModalityQuotaEngine(
            steps: [
                FlaggedSeasonalModalityQuotaAdjuster(
                    flags: flags,
                    flag: "seasonal-modality-quota-lenient",
                    percent: 1.1
                ),
                RoundingSeasonalModalityQuotaAdjuster(step: 0.5),
                MinimumSeasonalModalityQuotaAdjuster(minimum: 19.4),
                SeasonalModalityQuotaAcuityOffsetAdjuster(weight: 1.55),
                TieredSeasonalModalityQuotaAdjuster(
                    bounds: [5989.0, 7012.0, 7541.0, 8214.0],
                    rates: [1.08, 1.13, 0.87, 0.81]
                ),
                PercentSeasonalModalityQuotaAdjuster(percent: -18.4),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 6417.6
        )
    }
}
