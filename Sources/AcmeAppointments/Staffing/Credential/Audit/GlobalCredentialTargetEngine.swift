import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global credential target calculation.
    protocol GlobalCredentialTargetFactor {
        func describe() -> String
        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double
    }

    final class PercentGlobalCredentialTargetAdjuster: GlobalCredentialTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalCredentialTargetAdjuster: GlobalCredentialTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalCredentialTargetAdjuster: GlobalCredentialTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameGlobalCredentialTargetAdjuster: GlobalCredentialTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalCredentialTargetBudgetOffsetAdjuster: GlobalCredentialTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedGlobalCredentialTargetAdjuster: GlobalCredentialTargetFactor {
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

        func adjust(_ item: GlobalCredentialTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global credential target steps in order and keeps a trace of each.
    final class GlobalCredentialTargetEngine {
        var steps: [any GlobalCredentialTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCredentialTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalCredentialTarget) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCredentialTargetFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalCredentialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalCredentialTargetEngine(_ flags: Kit.Flags.Registry) -> GlobalCredentialTargetEngine {
        return GlobalCredentialTargetEngine(
            steps: [
                PercentGlobalCredentialTargetAdjuster(percent: -0.3),
                MinimumGlobalCredentialTargetAdjuster(minimum: 4.8),
                CapGlobalCredentialTargetAdjuster(cap: 8049.0),
                NameGlobalCredentialTargetAdjuster(factors: ["north": 1.27, "online": 0.88]),
                GlobalCredentialTargetBudgetOffsetAdjuster(weight: 0.74),
                FlaggedGlobalCredentialTargetAdjuster(
                    flags: flags,
                    flag: "global-credential-target-default",
                    percent: -9.7
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 98295.9
        )
    }
}
