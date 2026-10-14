import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global courier tier calculation.
    protocol GlobalCourierTierAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCourierTier, value: Double) -> Double
    }

    final class FlaggedGlobalCourierTierAdjuster: GlobalCourierTierAdjuster {
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

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalCourierTierAdjuster: GlobalCourierTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalCourierTierAdjuster: GlobalCourierTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelGlobalCourierTierAdjuster: GlobalCourierTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalCourierTierUpdatedAtOffsetAdjuster: GlobalCourierTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapGlobalCourierTierAdjuster: GlobalCourierTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCourierTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global courier tier steps in order and keeps a trace of each.
    final class GlobalCourierTierEngine {
        var steps: [any GlobalCourierTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCourierTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCourierTier) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCourierTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalCourierTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCourierTierEngine(_ flags: Kit.Flags.Registry) -> GlobalCourierTierEngine {
        return GlobalCourierTierEngine(
            steps: [
                FlaggedGlobalCourierTierAdjuster(flags: flags, flag: "global-courier-tier-strict", percent: 7.8),
                RoundingGlobalCourierTierAdjuster(step: 0.1),
                MinimumGlobalCourierTierAdjuster(minimum: 19.1),
                ChannelGlobalCourierTierAdjuster(factors: ["south": 0.81, "online": 1.15]),
                GlobalCourierTierUpdatedAtOffsetAdjuster(weight: 1.06),
                CapGlobalCourierTierAdjuster(cap: 8157.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 90439.1
        )
    }
}
