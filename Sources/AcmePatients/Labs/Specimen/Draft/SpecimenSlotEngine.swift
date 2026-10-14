import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen slot calculation.
    protocol SpecimenSlotAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenSlot, value: Double) -> Double
    }

    final class CapSpecimenSlotAdjuster: SpecimenSlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSpecimenSlotAdjuster: SpecimenSlotAdjuster {
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

        func adjust(_ item: SpecimenSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SpecimenSlotLimitOffsetAdjuster: SpecimenSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: SpecimenSlot, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the specimen slot steps in order and keeps a trace of each.
    final class SpecimenSlotEngine {
        var steps: [any SpecimenSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SpecimenSlot) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenSlotAdjuster = steps[index]
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

        func evaluateAll(_ items: [SpecimenSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSpecimenSlotEngine(_ flags: Kit.Flags.Registry) -> SpecimenSlotEngine {
        return SpecimenSlotEngine(
            steps: [
                CapSpecimenSlotAdjuster(cap: 33050.0),
                FlaggedSpecimenSlotAdjuster(flags: flags, flag: "specimen-slot-global", percent: 1.1),
                SpecimenSlotLimitOffsetAdjuster(weight: 0.12),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 46375.2
        )
    }
}
