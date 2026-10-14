import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global modality cycle calculation.
    protocol GlobalModalityCycleFactor {
        func describe() -> String
        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double
    }

    final class MinimumGlobalModalityCycleAdjuster: GlobalModalityCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalModalityCycleAdjuster: GlobalModalityCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalModalityCycleAdjuster: GlobalModalityCycleFactor {
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

        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalModalityCycleAdjuster: GlobalModalityCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelGlobalModalityCycleAdjuster: GlobalModalityCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalModalityCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global modality cycle steps in order and keeps a trace of each.
    final class GlobalModalityCycleEngine {
        var steps: [any GlobalModalityCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalModalityCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalModalityCycle) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalModalityCycleFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalModalityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalModalityCycleEngine(_ flags: Kit.Flags.Registry) -> GlobalModalityCycleEngine {
        return GlobalModalityCycleEngine(
            steps: [
                MinimumGlobalModalityCycleAdjuster(minimum: 40.3),
                PercentGlobalModalityCycleAdjuster(percent: 2.2),
                FlaggedGlobalModalityCycleAdjuster(flags: flags, flag: "global-modality-cycle-batched", percent: 1.6),
                RoundingGlobalModalityCycleAdjuster(step: 0.05),
                LabelGlobalModalityCycleAdjuster(factors: ["west": 0.76, "online": 1.27, "east": 0.72]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 33170.0
        )
    }
}
