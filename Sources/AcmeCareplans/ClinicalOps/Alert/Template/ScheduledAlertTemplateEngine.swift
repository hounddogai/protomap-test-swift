import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled alert template calculation.
    protocol ScheduledAlertTemplateModifier {
        func describe() -> String
        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double
    }

    final class FacilityScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
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

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledAlertTemplateAdjuster: ScheduledAlertTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAlertTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled alert template steps in order and keeps a trace of each.
    final class ScheduledAlertTemplateEngine {
        var steps: [any ScheduledAlertTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAlertTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledAlertTemplate) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAlertTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledAlertTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledAlertTemplateEngine(_ flags: Kit.Flags.Registry) -> ScheduledAlertTemplateEngine {
        return ScheduledAlertTemplateEngine(
            steps: [
                FacilityScheduledAlertTemplateAdjuster(factors: ["central": 0.99, "online": 0.84]),
                FlaggedScheduledAlertTemplateAdjuster(
                    flags: flags,
                    flag: "scheduled-alert-template-batched",
                    percent: 5.0
                ),
                MinimumScheduledAlertTemplateAdjuster(minimum: 42.3),
                TieredScheduledAlertTemplateAdjuster(bounds: [4680.0, 6743.0], rates: [0.88, 0.82]),
                RoundingScheduledAlertTemplateAdjuster(step: 5.0),
                CapScheduledAlertTemplateAdjuster(cap: 44744.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 53448.6
        )
    }
}
