import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy priority policy calculation.
    protocol LegacyPriorityPolicyStep {
        func describe() -> String
        func adjust(_ item: LegacyPriorityPolicy, value: Double) -> Double
    }

    final class RoundingLegacyPriorityPolicyAdjuster: LegacyPriorityPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyPriorityPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceLegacyPriorityPolicyAdjuster: LegacyPriorityPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LegacyPriorityPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLegacyPriorityPolicyAdjuster: LegacyPriorityPolicyStep {
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

        func adjust(_ item: LegacyPriorityPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyPriorityPolicyAdjuster: LegacyPriorityPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyPriorityPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy priority policy steps in order and keeps a trace of each.
    final class LegacyPriorityPolicyEngine {
        var steps: [any LegacyPriorityPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyPriorityPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyPriorityPolicy) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyPriorityPolicyStep = steps[index]
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

        func evaluateAll(_ items: [LegacyPriorityPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyPriorityPolicyEngine(_ flags: Kit.Flags.Registry) -> LegacyPriorityPolicyEngine {
        return LegacyPriorityPolicyEngine(
            steps: [
                RoundingLegacyPriorityPolicyAdjuster(step: 0.05),
                SourceLegacyPriorityPolicyAdjuster(factors: ["north": 1.37, "east": 1.29]),
                FlaggedLegacyPriorityPolicyAdjuster(
                    flags: flags,
                    flag: "legacy-priority-policy-fallback",
                    percent: 5.5
                ),
                CapLegacyPriorityPolicyAdjuster(cap: 46685.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 18643.8
        )
    }
}
