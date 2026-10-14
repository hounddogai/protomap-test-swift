import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy credential schedule calculation.
    protocol LegacyCredentialScheduleModifier {
        func describe() -> String
        func adjust(_ item: LegacyCredentialSchedule, value: Double) -> Double
    }

    final class TieredLegacyCredentialScheduleAdjuster: LegacyCredentialScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCredentialSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyCredentialScheduleAdjuster: LegacyCredentialScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCredentialSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyCredentialScheduleAdjuster: LegacyCredentialScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCredentialSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy credential schedule steps in order and keeps a trace of each.
    final class LegacyCredentialScheduleEngine {
        var steps: [any LegacyCredentialScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCredentialScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyCredentialSchedule) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCredentialScheduleModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyCredentialSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyCredentialScheduleEngine() -> LegacyCredentialScheduleEngine {
        return LegacyCredentialScheduleEngine(
            steps: [
                TieredLegacyCredentialScheduleAdjuster(
                    bounds: [3441.0, 3454.0, 7022.0, 7811.0],
                    rates: [0.98, 0.98, 0.97, 1.17]
                ),
                RoundingLegacyCredentialScheduleAdjuster(step: 0.05),
                MinimumLegacyCredentialScheduleAdjuster(minimum: 49.3),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 70772.2
        )
    }
}
