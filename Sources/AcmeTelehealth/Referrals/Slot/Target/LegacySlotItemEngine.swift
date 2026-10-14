import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy slot item calculation.
    protocol LegacySlotItemModifier {
        func describe() -> String
        func adjust(_ item: LegacySlotItem, value: Double) -> Double
    }

    final class RoundingLegacySlotItemAdjuster: LegacySlotItemModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySlotItem, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacySlotItemAdjuster: LegacySlotItemModifier {
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

        func adjust(_ item: LegacySlotItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLegacySlotItemAdjuster: LegacySlotItemModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacySlotItem, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacySlotItemAdjuster: LegacySlotItemModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacySlotItem, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacySlotItemAdjuster: LegacySlotItemModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySlotItem, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy slot item steps in order and keeps a trace of each.
    final class LegacySlotItemEngine {
        var steps: [any LegacySlotItemModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySlotItemModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacySlotItem) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [LegacySlotItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacySlotItemEngine(_ flags: Kit.Flags.Registry) -> LegacySlotItemEngine {
        return LegacySlotItemEngine(
            steps: [
                RoundingLegacySlotItemAdjuster(step: 0.5),
                FlaggedLegacySlotItemAdjuster(flags: flags, flag: "legacy-slot-item-primary", percent: 2.2),
                TitleLegacySlotItemAdjuster(factors: ["central": 1.22, "north": 1.08, "retail": 1.07]),
                MinimumLegacySlotItemAdjuster(minimum: 6.1),
                CapLegacySlotItemAdjuster(cap: 22902.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 51559.5
        )
    }
}
