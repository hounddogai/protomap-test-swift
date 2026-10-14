import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense template calculation.
    protocol DispenseTemplateStep {
        func describe() -> String
        func adjust(_ item: DispenseTemplate, value: Double) -> Double
    }

    final class MinimumDispenseTemplateAdjuster: DispenseTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDispenseTemplateAdjuster: DispenseTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDispenseTemplateAdjuster: DispenseTemplateStep {
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

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DispenseTemplateBatchSizeOffsetAdjuster: DispenseTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class RoundingDispenseTemplateAdjuster: DispenseTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDispenseTemplateAdjuster: DispenseTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the dispense template steps in order and keeps a trace of each.
    final class DispenseTemplateEngine {
        var steps: [any DispenseTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseTemplate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseTemplateStep = steps[index]
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

        func evaluateAll(_ items: [DispenseTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseTemplateEngine(_ flags: Kit.Flags.Registry) -> DispenseTemplateEngine {
        return DispenseTemplateEngine(
            steps: [
                MinimumDispenseTemplateAdjuster(minimum: 41.6),
                PercentDispenseTemplateAdjuster(percent: 5.4),
                FlaggedDispenseTemplateAdjuster(flags: flags, flag: "dispense-template-adaptive", percent: -5.1),
                DispenseTemplateBatchSizeOffsetAdjuster(weight: 1.95),
                RoundingDispenseTemplateAdjuster(step: 0.25),
                TieredDispenseTemplateAdjuster(bounds: [1297.0, 8951.0, 9755.0], rates: [0.91, 1.01, 1.07]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 15806.3
        )
    }
}
