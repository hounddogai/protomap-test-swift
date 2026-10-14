import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary shift forecast calculation.
    protocol PrimaryShiftForecastModifier {
        func describe() -> String
        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double
    }

    final class CapPrimaryShiftForecastAdjuster: PrimaryShiftForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryShiftForecastAdjuster: PrimaryShiftForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryShiftForecastAdjuster: PrimaryShiftForecastModifier {
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

        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryShiftForecastCreatedAtOffsetAdjuster: PrimaryShiftForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class LabelPrimaryShiftForecastAdjuster: PrimaryShiftForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryShiftForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary shift forecast steps in order and keeps a trace of each.
    final class PrimaryShiftForecastEngine {
        var steps: [any PrimaryShiftForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryShiftForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryShiftForecast) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryShiftForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryShiftForecastEngine(_ flags: Kit.Flags.Registry) -> PrimaryShiftForecastEngine {
        return PrimaryShiftForecastEngine(
            steps: [
                CapPrimaryShiftForecastAdjuster(cap: 17991.0),
                MinimumPrimaryShiftForecastAdjuster(minimum: 47.9),
                FlaggedPrimaryShiftForecastAdjuster(
                    flags: flags,
                    flag: "primary-shift-forecast-default",
                    percent: 7.0
                ),
                PrimaryShiftForecastCreatedAtOffsetAdjuster(weight: 0.19),
                LabelPrimaryShiftForecastAdjuster(factors: ["north": 1.07]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 48214.1
        )
    }
}
