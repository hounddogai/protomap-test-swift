import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance tier calculation.
    protocol RemittanceTierFactor {
        func describe() -> String
        func adjust(_ item: RemittanceTier, value: Double) -> Double
    }

    final class CapRemittanceTierAdjuster: RemittanceTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRemittanceTierAdjuster: RemittanceTierFactor {
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

        func adjust(_ item: RemittanceTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceTierAdjuster: RemittanceTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRemittanceTierAdjuster: RemittanceTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the remittance tier steps in order and keeps a trace of each.
    final class RemittanceTierEngine {
        var steps: [any RemittanceTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceTier) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceTierFactor = steps[index]
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

        func evaluateAll(_ items: [RemittanceTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceTierEngine(_ flags: Kit.Flags.Registry) -> RemittanceTierEngine {
        return RemittanceTierEngine(
            steps: [
                CapRemittanceTierAdjuster(cap: 37165.0),
                FlaggedRemittanceTierAdjuster(flags: flags, flag: "remittance-tier-adaptive", percent: 9.4),
                MinimumRemittanceTierAdjuster(minimum: 15.8),
                RoundingRemittanceTierAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 47537.9
        )
    }
}
