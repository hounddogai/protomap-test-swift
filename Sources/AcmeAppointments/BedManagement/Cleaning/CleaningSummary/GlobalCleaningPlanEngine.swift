import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global cleaning plan calculation.
    protocol GlobalCleaningPlanModifier {
        func describe() -> String
        func adjust(_ item: GlobalCleaningPlan, value: Double) -> Double
    }

    final class ChannelGlobalCleaningPlanAdjuster: GlobalCleaningPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalCleaningPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalCleaningPlanAdjuster: GlobalCleaningPlanModifier {
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

        func adjust(_ item: GlobalCleaningPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalCleaningPlanAdjuster: GlobalCleaningPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCleaningPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global cleaning plan steps in order and keeps a trace of each.
    final class GlobalCleaningPlanEngine {
        var steps: [any GlobalCleaningPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCleaningPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalCleaningPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCleaningPlanModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalCleaningPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalCleaningPlanEngine(_ flags: Kit.Flags.Registry) -> GlobalCleaningPlanEngine {
        return GlobalCleaningPlanEngine(
            steps: [
                ChannelGlobalCleaningPlanAdjuster(factors: ["south": 1.1, "east": 0.93]),
                FlaggedGlobalCleaningPlanAdjuster(flags: flags, flag: "global-cleaning-plan-scheduled", percent: -2.1),
                TieredGlobalCleaningPlanAdjuster(bounds: [1091.0, 2670.0, 3857.0], rates: [1.09, 0.85, 1.0]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 35105.7
        )
    }
}
