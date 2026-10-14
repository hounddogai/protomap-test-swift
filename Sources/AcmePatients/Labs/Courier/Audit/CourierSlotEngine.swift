import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier slot calculation.
    protocol CourierSlotModifier {
        func describe() -> String
        func adjust(_ item: CourierSlot, value: Double) -> Double
    }

    final class PercentCourierSlotAdjuster: CourierSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentCourierSlotAdjuster: CourierSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CourierSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCourierSlotAdjuster: CourierSlotModifier {
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

        func adjust(_ item: CourierSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier slot steps in order and keeps a trace of each.
    final class CourierSlotEngine {
        var steps: [any CourierSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierSlot) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [CourierSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierSlotEngine(_ flags: Kit.Flags.Registry) -> CourierSlotEngine {
        return CourierSlotEngine(
            steps: [
                PercentCourierSlotAdjuster(percent: 4.0),
                SegmentCourierSlotAdjuster(factors: ["north": 1.05, "online": 1.18]),
                FlaggedCourierSlotAdjuster(flags: flags, flag: "courier-slot-global", percent: -9.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 30429.3
        )
    }
}
