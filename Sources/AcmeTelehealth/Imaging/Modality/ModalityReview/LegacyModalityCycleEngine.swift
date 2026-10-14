import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy modality cycle calculation.
    protocol LegacyModalityCycleModifier {
        func describe() -> String
        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double
    }

    final class CountryLegacyModalityCycleAdjuster: LegacyModalityCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyModalityCycleAdjuster: LegacyModalityCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyModalityCycleAdjuster: LegacyModalityCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyModalityCycleCreatedAtOffsetAdjuster: LegacyModalityCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumLegacyModalityCycleAdjuster: LegacyModalityCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyModalityCycleAdjuster: LegacyModalityCycleModifier {
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

        func adjust(_ item: LegacyModalityCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy modality cycle steps in order and keeps a trace of each.
    final class LegacyModalityCycleEngine {
        var steps: [any LegacyModalityCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyModalityCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyModalityCycle) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyModalityCycleModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyModalityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyModalityCycleEngine(_ flags: Kit.Flags.Registry) -> LegacyModalityCycleEngine {
        return LegacyModalityCycleEngine(
            steps: [
                CountryLegacyModalityCycleAdjuster(factors: ["east": 1.34, "retail": 1.27]),
                RoundingLegacyModalityCycleAdjuster(step: 1.0),
                TieredLegacyModalityCycleAdjuster(bounds: [661.0, 7746.0, 8822.0], rates: [1.11, 1.17, 0.82]),
                LegacyModalityCycleCreatedAtOffsetAdjuster(weight: 1.53),
                MinimumLegacyModalityCycleAdjuster(minimum: 24.3),
                FlaggedLegacyModalityCycleAdjuster(flags: flags, flag: "legacy-modality-cycle-seasonal", percent: 6.1),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 66524.0
        )
    }
}
