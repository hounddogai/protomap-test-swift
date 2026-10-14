import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure bundle calculation.
    protocol SeasonalClosureBundleModifier {
        func describe() -> String
        func adjust(_ item: SeasonalClosureBundle, value: Double) -> Double
    }

    final class FlaggedSeasonalClosureBundleAdjuster: SeasonalClosureBundleModifier {
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

        func adjust(_ item: SeasonalClosureBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalClosureBundleRateOffsetAdjuster: SeasonalClosureBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: SeasonalClosureBundle, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentSeasonalClosureBundleAdjuster: SeasonalClosureBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalClosureBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategorySeasonalClosureBundleAdjuster: SeasonalClosureBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SeasonalClosureBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal closure bundle steps in order and keeps a trace of each.
    final class SeasonalClosureBundleEngine {
        var steps: [any SeasonalClosureBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalClosureBundle) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalClosureBundleModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalClosureBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureBundleEngine(_ flags: Kit.Flags.Registry) -> SeasonalClosureBundleEngine {
        return SeasonalClosureBundleEngine(
            steps: [
                FlaggedSeasonalClosureBundleAdjuster(
                    flags: flags,
                    flag: "seasonal-closure-bundle-capped",
                    percent: 7.5
                ),
                SeasonalClosureBundleRateOffsetAdjuster(weight: 0.81),
                PercentSeasonalClosureBundleAdjuster(percent: -24.7),
                CategorySeasonalClosureBundleAdjuster(factors: ["central": 0.8, "east": 1.29, "retail": 1.38]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 1849.1
        )
    }
}
