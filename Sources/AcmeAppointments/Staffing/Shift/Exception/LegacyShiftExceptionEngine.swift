import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy shift exception calculation.
    protocol LegacyShiftExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyShiftException, value: Double) -> Double
    }

    final class TieredLegacyShiftExceptionAdjuster: LegacyShiftExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyShiftException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyShiftExceptionRateOffsetAdjuster: LegacyShiftExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: LegacyShiftException, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedLegacyShiftExceptionAdjuster: LegacyShiftExceptionAdjuster {
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

        func adjust(_ item: LegacyShiftException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyShiftExceptionAdjuster: LegacyShiftExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyShiftException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameLegacyShiftExceptionAdjuster: LegacyShiftExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyShiftException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy shift exception steps in order and keeps a trace of each.
    final class LegacyShiftExceptionEngine {
        var steps: [any LegacyShiftExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyShiftExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyShiftException) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyShiftExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyShiftException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyShiftExceptionEngine(_ flags: Kit.Flags.Registry) -> LegacyShiftExceptionEngine {
        return LegacyShiftExceptionEngine(
            steps: [
                TieredLegacyShiftExceptionAdjuster(bounds: [19.0, 48.0, 2880.0], rates: [0.95, 0.95, 1.05]),
                LegacyShiftExceptionRateOffsetAdjuster(weight: 0.7),
                FlaggedLegacyShiftExceptionAdjuster(
                    flags: flags,
                    flag: "legacy-shift-exception-fallback",
                    percent: 7.2
                ),
                MinimumLegacyShiftExceptionAdjuster(minimum: 10.5),
                NameLegacyShiftExceptionAdjuster(factors: ["east": 0.82]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 84417.4
        )
    }
}
