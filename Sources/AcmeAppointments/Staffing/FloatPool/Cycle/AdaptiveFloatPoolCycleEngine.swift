import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive float pool cycle calculation.
    protocol AdaptiveFloatPoolCycleStep {
        func describe() -> String
        func adjust(_ item: AdaptiveFloatPoolCycle, value: Double) -> Double
    }

    final class PercentAdaptiveFloatPoolCycleAdjuster: AdaptiveFloatPoolCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFloatPoolCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAdaptiveFloatPoolCycleAdjuster: AdaptiveFloatPoolCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveFloatPoolCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveFloatPoolCycleWindowDaysOffsetAdjuster: AdaptiveFloatPoolCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AdaptiveFloatPoolCycle, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedAdaptiveFloatPoolCycleAdjuster: AdaptiveFloatPoolCycleStep {
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

        func adjust(_ item: AdaptiveFloatPoolCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive float pool cycle steps in order and keeps a trace of each.
    final class AdaptiveFloatPoolCycleEngine {
        var steps: [any AdaptiveFloatPoolCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFloatPoolCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveFloatPoolCycle) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [AdaptiveFloatPoolCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFloatPoolCycleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveFloatPoolCycleEngine {
        return AdaptiveFloatPoolCycleEngine(
            steps: [
                PercentAdaptiveFloatPoolCycleAdjuster(percent: -9.9),
                LabelAdaptiveFloatPoolCycleAdjuster(factors: ["central": 1.19]),
                AdaptiveFloatPoolCycleWindowDaysOffsetAdjuster(weight: 1.56),
                FlaggedAdaptiveFloatPoolCycleAdjuster(
                    flags: flags,
                    flag: "adaptive-float-pool-cycle-pending",
                    percent: -7.7
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 43247.3
        )
    }
}
