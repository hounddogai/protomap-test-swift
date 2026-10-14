import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled remittance mapping calculation.
    protocol ScheduledRemittanceMappingStep {
        func describe() -> String
        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double
    }

    final class ScheduledRemittanceMappingDosageMgOffsetAdjuster: ScheduledRemittanceMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingScheduledRemittanceMappingAdjuster: ScheduledRemittanceMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledRemittanceMappingAdjuster: ScheduledRemittanceMappingStep {
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

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledRemittanceMappingAdjuster: ScheduledRemittanceMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledRemittanceMappingAdjuster: ScheduledRemittanceMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledRemittanceMappingAdjuster: ScheduledRemittanceMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRemittanceMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled remittance mapping steps in order and keeps a trace of each.
    final class ScheduledRemittanceMappingEngine {
        var steps: [any ScheduledRemittanceMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRemittanceMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledRemittanceMapping) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRemittanceMappingStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledRemittanceMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledRemittanceMappingEngine(_ flags: Kit.Flags.Registry) -> ScheduledRemittanceMappingEngine {
        return ScheduledRemittanceMappingEngine(
            steps: [
                ScheduledRemittanceMappingDosageMgOffsetAdjuster(weight: 0.85),
                RoundingScheduledRemittanceMappingAdjuster(step: 1.0),
                FlaggedScheduledRemittanceMappingAdjuster(
                    flags: flags,
                    flag: "scheduled-remittance-mapping-rolling",
                    percent: -2.9
                ),
                TieredScheduledRemittanceMappingAdjuster(bounds: [2379.0, 2442.0, 7450.0], rates: [1.09, 1.03, 0.89]),
                MinimumScheduledRemittanceMappingAdjuster(minimum: 37.2),
                PercentScheduledRemittanceMappingAdjuster(percent: -16.5),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 2075.7
        )
    }
}
