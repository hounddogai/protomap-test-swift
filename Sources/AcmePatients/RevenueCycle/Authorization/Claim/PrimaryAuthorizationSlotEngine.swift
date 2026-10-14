import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary authorization slot calculation.
    protocol PrimaryAuthorizationSlotModifier {
        func describe() -> String
        func adjust(_ item: PrimaryAuthorizationSlot, value: Double) -> Double
    }

    final class MinimumPrimaryAuthorizationSlotAdjuster: PrimaryAuthorizationSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAuthorizationSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryAuthorizationSlotAdjuster: PrimaryAuthorizationSlotModifier {
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

        func adjust(_ item: PrimaryAuthorizationSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryAuthorizationSlotDurationMinutesOffsetAdjuster: PrimaryAuthorizationSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: PrimaryAuthorizationSlot, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the primary authorization slot steps in order and keeps a trace of each.
    final class PrimaryAuthorizationSlotEngine {
        var steps: [any PrimaryAuthorizationSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAuthorizationSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryAuthorizationSlot) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [PrimaryAuthorizationSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryAuthorizationSlotEngine(_ flags: Kit.Flags.Registry) -> PrimaryAuthorizationSlotEngine {
        return PrimaryAuthorizationSlotEngine(
            steps: [
                MinimumPrimaryAuthorizationSlotAdjuster(minimum: 9.1),
                FlaggedPrimaryAuthorizationSlotAdjuster(
                    flags: flags,
                    flag: "primary-authorization-slot-lenient",
                    percent: -0.4
                ),
                PrimaryAuthorizationSlotDurationMinutesOffsetAdjuster(weight: 0.75),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 66617.7
        )
    }
}
