import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning threshold calculation.
    protocol CleaningThresholdModifier {
        func describe() -> String
        func adjust(_ item: CleaningThreshold, value: Double) -> Double
    }

    final class LabelCleaningThresholdAdjuster: CleaningThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CleaningThresholdEndsAtOffsetAdjuster: CleaningThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentCleaningThresholdAdjuster: CleaningThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCleaningThresholdAdjuster: CleaningThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCleaningThresholdAdjuster: CleaningThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCleaningThresholdAdjuster: CleaningThresholdModifier {
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

        func adjust(_ item: CleaningThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the cleaning threshold steps in order and keeps a trace of each.
    final class CleaningThresholdEngine {
        var steps: [any CleaningThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningThreshold) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CleaningThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningThresholdEngine(_ flags: Kit.Flags.Registry) -> CleaningThresholdEngine {
        return CleaningThresholdEngine(
            steps: [
                LabelCleaningThresholdAdjuster(factors: ["east": 0.72, "south": 0.89, "central": 1.18]),
                CleaningThresholdEndsAtOffsetAdjuster(weight: 1.29),
                PercentCleaningThresholdAdjuster(percent: -13.6),
                CapCleaningThresholdAdjuster(cap: 49488.0),
                MinimumCleaningThresholdAdjuster(minimum: 12.0),
                FlaggedCleaningThresholdAdjuster(flags: flags, flag: "cleaning-threshold-weighted", percent: -6.8),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 1664.6
        )
    }
}
