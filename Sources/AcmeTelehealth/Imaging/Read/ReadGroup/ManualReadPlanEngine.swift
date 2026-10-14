import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual read plan calculation.
    protocol ManualReadPlanStep {
        func describe() -> String
        func adjust(_ item: ManualReadPlan, value: Double) -> Double
    }

    final class MinimumManualReadPlanAdjuster: ManualReadPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualReadPlanAdjuster: ManualReadPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualReadPlanAdjuster: ManualReadPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualReadPlanAdjuster: ManualReadPlanStep {
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

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualReadPlanAdjuster: ManualReadPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualReadPlanBatchSizeOffsetAdjuster: ManualReadPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ManualReadPlan, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the manual read plan steps in order and keeps a trace of each.
    final class ManualReadPlanEngine {
        var steps: [any ManualReadPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualReadPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualReadPlan) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ManualReadPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualReadPlanEngine(_ flags: Kit.Flags.Registry) -> ManualReadPlanEngine {
        return ManualReadPlanEngine(
            steps: [
                MinimumManualReadPlanAdjuster(minimum: 33.7),
                CapManualReadPlanAdjuster(cap: 6872.0),
                TieredManualReadPlanAdjuster(
                    bounds: [4780.0, 5360.0, 8880.0, 9339.0],
                    rates: [1.19, 0.92, 0.85, 1.04]
                ),
                FlaggedManualReadPlanAdjuster(flags: flags, flag: "manual-read-plan-capped", percent: -6.4),
                PercentManualReadPlanAdjuster(percent: 14.2),
                ManualReadPlanBatchSizeOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 88659.7
        )
    }
}
