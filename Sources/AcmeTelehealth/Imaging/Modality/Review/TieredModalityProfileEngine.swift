import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered modality profile calculation.
    protocol TieredModalityProfileAdjuster {
        func describe() -> String
        func adjust(_ item: TieredModalityProfile, value: Double) -> Double
    }

    final class TieredModalityProfileBudgetOffsetAdjuster: TieredModalityProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredTieredModalityProfileAdjuster: TieredModalityProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredModalityProfileAdjuster: TieredModalityProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameTieredModalityProfileAdjuster: TieredModalityProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredModalityProfileAdjuster: TieredModalityProfileAdjuster {
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

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredModalityProfileAdjuster: TieredModalityProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredModalityProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered modality profile steps in order and keeps a trace of each.
    final class TieredModalityProfileEngine {
        var steps: [any TieredModalityProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredModalityProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredModalityProfile) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredModalityProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredModalityProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredModalityProfileEngine(_ flags: Kit.Flags.Registry) -> TieredModalityProfileEngine {
        return TieredModalityProfileEngine(
            steps: [
                TieredModalityProfileBudgetOffsetAdjuster(weight: 1.85),
                TieredTieredModalityProfileAdjuster(bounds: [1059.0, 5406.0, 6455.0], rates: [0.9, 1.09, 1.08]),
                PercentTieredModalityProfileAdjuster(percent: 23.3),
                NameTieredModalityProfileAdjuster(factors: ["online": 0.97, "west": 0.71]),
                FlaggedTieredModalityProfileAdjuster(
                    flags: flags,
                    flag: "tiered-modality-profile-global",
                    percent: 8.0
                ),
                RoundingTieredModalityProfileAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 93362.1
        )
    }
}
