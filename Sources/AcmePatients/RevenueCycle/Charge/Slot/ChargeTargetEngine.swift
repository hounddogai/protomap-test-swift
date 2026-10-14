import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge target calculation.
    protocol ChargeTargetModifier {
        func describe() -> String
        func adjust(_ item: ChargeTarget, value: Double) -> Double
    }

    final class FlaggedChargeTargetAdjuster: ChargeTargetModifier {
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

        func adjust(_ item: ChargeTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChargeTargetStartsAtOffsetAdjuster: ChargeTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ChargeTarget, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class MinimumChargeTargetAdjuster: ChargeTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the charge target steps in order and keeps a trace of each.
    final class ChargeTargetEngine {
        var steps: [any ChargeTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeTarget) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeTargetModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeTargetEngine(_ flags: Kit.Flags.Registry) -> ChargeTargetEngine {
        return ChargeTargetEngine(
            steps: [
                FlaggedChargeTargetAdjuster(flags: flags, flag: "charge-target-fallback", percent: 7.4),
                ChargeTargetStartsAtOffsetAdjuster(weight: 1.01),
                MinimumChargeTargetAdjuster(minimum: 29.7),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 91772.1
        )
    }
}
