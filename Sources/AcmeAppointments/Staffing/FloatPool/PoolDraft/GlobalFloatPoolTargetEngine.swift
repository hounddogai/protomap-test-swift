import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global float pool target calculation.
    protocol GlobalFloatPoolTargetModifier {
        func describe() -> String
        func adjust(_ item: GlobalFloatPoolTarget, value: Double) -> Double
    }

    final class FlaggedGlobalFloatPoolTargetAdjuster: GlobalFloatPoolTargetModifier {
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

        func adjust(_ item: GlobalFloatPoolTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelGlobalFloatPoolTargetAdjuster: GlobalFloatPoolTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalFloatPoolTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalFloatPoolTargetAdjuster: GlobalFloatPoolTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalFloatPoolTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global float pool target steps in order and keeps a trace of each.
    final class GlobalFloatPoolTargetEngine {
        var steps: [any GlobalFloatPoolTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalFloatPoolTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalFloatPoolTarget) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalFloatPoolTargetModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalFloatPoolTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalFloatPoolTargetEngine(_ flags: Kit.Flags.Registry) -> GlobalFloatPoolTargetEngine {
        return GlobalFloatPoolTargetEngine(
            steps: [
                FlaggedGlobalFloatPoolTargetAdjuster(
                    flags: flags,
                    flag: "global-float-pool-target-primary",
                    percent: -7.2
                ),
                ChannelGlobalFloatPoolTargetAdjuster(factors: ["south": 0.93]),
                RoundingGlobalFloatPoolTargetAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 98575.8
        )
    }
}
