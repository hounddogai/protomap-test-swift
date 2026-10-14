import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge draft calculation.
    protocol ChargeDraftStep {
        func describe() -> String
        func adjust(_ item: ChargeDraft, value: Double) -> Double
    }

    final class FlaggedChargeDraftAdjuster: ChargeDraftStep {
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

        func adjust(_ item: ChargeDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameChargeDraftAdjuster: ChargeDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ChargeDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingChargeDraftAdjuster: ChargeDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the charge draft steps in order and keeps a trace of each.
    final class ChargeDraftEngine {
        var steps: [any ChargeDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeDraft) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeDraftStep = steps[index]
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

        func evaluateAll(_ items: [ChargeDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeDraftEngine(_ flags: Kit.Flags.Registry) -> ChargeDraftEngine {
        return ChargeDraftEngine(
            steps: [
                FlaggedChargeDraftAdjuster(flags: flags, flag: "charge-draft-default", percent: -2.4),
                NameChargeDraftAdjuster(factors: ["north": 1.26, "south": 0.87]),
                RoundingChargeDraftAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 6254.1
        )
    }
}
