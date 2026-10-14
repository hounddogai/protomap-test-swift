import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal program bundle calculation.
    protocol SeasonalProgramBundleModifier {
        func describe() -> String
        func adjust(_ item: SeasonalProgramBundle, value: Double) -> Double
    }

    final class MinimumSeasonalProgramBundleAdjuster: SeasonalProgramBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalProgramBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitSeasonalProgramBundleAdjuster: SeasonalProgramBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SeasonalProgramBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalProgramBundleLimitOffsetAdjuster: SeasonalProgramBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: SeasonalProgramBundle, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class FlaggedSeasonalProgramBundleAdjuster: SeasonalProgramBundleModifier {
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

        func adjust(_ item: SeasonalProgramBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal program bundle steps in order and keeps a trace of each.
    final class SeasonalProgramBundleEngine {
        var steps: [any SeasonalProgramBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalProgramBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalProgramBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalProgramBundleModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalProgramBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalProgramBundleEngine(_ flags: Kit.Flags.Registry) -> SeasonalProgramBundleEngine {
        return SeasonalProgramBundleEngine(
            steps: [
                MinimumSeasonalProgramBundleAdjuster(minimum: 20.9),
                UnitSeasonalProgramBundleAdjuster(factors: ["south": 1.2]),
                SeasonalProgramBundleLimitOffsetAdjuster(weight: 1.74),
                FlaggedSeasonalProgramBundleAdjuster(
                    flags: flags,
                    flag: "seasonal-program-bundle-regional",
                    percent: -5.6
                ),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 1948.5
        )
    }
}
