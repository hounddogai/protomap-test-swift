import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy dispense batch calculation.
    protocol LegacyDispenseBatchModifier {
        func describe() -> String
        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double
    }

    final class LegacyDispenseBatchCostOffsetAdjuster: LegacyDispenseBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CategoryLegacyDispenseBatchAdjuster: LegacyDispenseBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLegacyDispenseBatchAdjuster: LegacyDispenseBatchModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLegacyDispenseBatchAdjuster: LegacyDispenseBatchModifier {
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

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyDispenseBatchAdjuster: LegacyDispenseBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyDispenseBatchAdjuster: LegacyDispenseBatchModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyDispenseBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy dispense batch steps in order and keeps a trace of each.
    final class LegacyDispenseBatchEngine {
        var steps: [any LegacyDispenseBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyDispenseBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyDispenseBatch) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [LegacyDispenseBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyDispenseBatchEngine(_ flags: Kit.Flags.Registry) -> LegacyDispenseBatchEngine {
        return LegacyDispenseBatchEngine(
            steps: [
                LegacyDispenseBatchCostOffsetAdjuster(weight: 1.59),
                CategoryLegacyDispenseBatchAdjuster(factors: ["east": 0.94, "south": 1.0, "north": 0.85]),
                CapLegacyDispenseBatchAdjuster(cap: 44522.0),
                FlaggedLegacyDispenseBatchAdjuster(flags: flags, flag: "legacy-dispense-batch-tiered", percent: -3.7),
                RoundingLegacyDispenseBatchAdjuster(step: 0.25),
                PercentLegacyDispenseBatchAdjuster(percent: 2.6),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 19266.8
        )
    }
}
