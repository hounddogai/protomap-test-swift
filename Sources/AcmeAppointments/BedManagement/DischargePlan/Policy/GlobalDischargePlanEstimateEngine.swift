import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global discharge plan estimate calculation.
    protocol GlobalDischargePlanEstimateStep {
        func describe() -> String
        func adjust(_ item: GlobalDischargePlanEstimate, value: Double) -> Double
    }

    final class RoundingGlobalDischargePlanEstimateAdjuster: GlobalDischargePlanEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalDischargePlanEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalDischargePlanEstimateAdjuster: GlobalDischargePlanEstimateStep {
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

        func adjust(_ item: GlobalDischargePlanEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalDischargePlanEstimateAdjuster: GlobalDischargePlanEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalDischargePlanEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global discharge plan estimate steps in order and keeps a trace of each.
    final class GlobalDischargePlanEstimateEngine {
        var steps: [any GlobalDischargePlanEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDischargePlanEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalDischargePlanEstimate) -> Double {
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

        func evaluateAll(_ items: [GlobalDischargePlanEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalDischargePlanEstimateEngine(_ flags: Kit.Flags.Registry) -> GlobalDischargePlanEstimateEngine {
        return GlobalDischargePlanEstimateEngine(
            steps: [
                RoundingGlobalDischargePlanEstimateAdjuster(step: 5.0),
                FlaggedGlobalDischargePlanEstimateAdjuster(
                    flags: flags,
                    flag: "global-discharge-plan-estimate-regional",
                    percent: 6.6
                ),
                MinimumGlobalDischargePlanEstimateAdjuster(minimum: 46.5),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 10006.3
        )
    }
}
