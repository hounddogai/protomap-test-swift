import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal substitution exception calculation.
    protocol SeasonalSubstitutionExceptionModifier {
        func describe() -> String
        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double
    }

    final class RoundingSeasonalSubstitutionExceptionAdjuster: SeasonalSubstitutionExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalSubstitutionExceptionAdjuster: SeasonalSubstitutionExceptionModifier {
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

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalSubstitutionExceptionAdjuster: SeasonalSubstitutionExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalSubstitutionExceptionFloorValueOffsetAdjuster: SeasonalSubstitutionExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumSeasonalSubstitutionExceptionAdjuster: SeasonalSubstitutionExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitSeasonalSubstitutionExceptionAdjuster: SeasonalSubstitutionExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SeasonalSubstitutionException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal substitution exception steps in order and keeps a trace of each.
    final class SeasonalSubstitutionExceptionEngine {
        var steps: [any SeasonalSubstitutionExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSubstitutionExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalSubstitutionException) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalSubstitutionExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalSubstitutionException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalSubstitutionExceptionEngine(_ flags: Kit.Flags.Registry) -> SeasonalSubstitutionExceptionEngine {
        return SeasonalSubstitutionExceptionEngine(
            steps: [
                RoundingSeasonalSubstitutionExceptionAdjuster(step: 0.5),
                FlaggedSeasonalSubstitutionExceptionAdjuster(
                    flags: flags,
                    flag: "seasonal-substitution-exception-legacy",
                    percent: -7.0
                ),
                CapSeasonalSubstitutionExceptionAdjuster(cap: 27231.0),
                SeasonalSubstitutionExceptionFloorValueOffsetAdjuster(weight: 0.25),
                MinimumSeasonalSubstitutionExceptionAdjuster(minimum: 49.9),
                UnitSeasonalSubstitutionExceptionAdjuster(factors: ["south": 0.73]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 58310.9
        )
    }
}
