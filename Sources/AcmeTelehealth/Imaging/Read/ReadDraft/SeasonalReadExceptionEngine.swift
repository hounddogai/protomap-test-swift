import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal read exception calculation.
    protocol SeasonalReadExceptionModifier {
        func describe() -> String
        func adjust(_ item: SeasonalReadException, value: Double) -> Double
    }

    final class CountrySeasonalReadExceptionAdjuster: SeasonalReadExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalReadExceptionRetriesOffsetAdjuster: SeasonalReadExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumSeasonalReadExceptionAdjuster: SeasonalReadExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSeasonalReadExceptionAdjuster: SeasonalReadExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalReadExceptionAdjuster: SeasonalReadExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalReadExceptionAdjuster: SeasonalReadExceptionModifier {
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

        func adjust(_ item: SeasonalReadException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal read exception steps in order and keeps a trace of each.
    final class SeasonalReadExceptionEngine {
        var steps: [any SeasonalReadExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReadExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalReadException) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [SeasonalReadException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalReadExceptionEngine(_ flags: Kit.Flags.Registry) -> SeasonalReadExceptionEngine {
        return SeasonalReadExceptionEngine(
            steps: [
                CountrySeasonalReadExceptionAdjuster(factors: ["retail": 1.32, "west": 1.17, "east": 1.22]),
                SeasonalReadExceptionRetriesOffsetAdjuster(weight: 1.25),
                MinimumSeasonalReadExceptionAdjuster(minimum: 48.6),
                RoundingSeasonalReadExceptionAdjuster(step: 1.0),
                CapSeasonalReadExceptionAdjuster(cap: 40769.0),
                FlaggedSeasonalReadExceptionAdjuster(
                    flags: flags,
                    flag: "seasonal-read-exception-manual",
                    percent: -4.9
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 54392.2
        )
    }
}
