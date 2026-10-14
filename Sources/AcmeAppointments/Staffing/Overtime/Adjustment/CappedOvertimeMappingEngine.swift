import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped overtime mapping calculation.
    protocol CappedOvertimeMappingModifier {
        func describe() -> String
        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double
    }

    final class FlaggedCappedOvertimeMappingAdjuster: CappedOvertimeMappingModifier {
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

        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitCappedOvertimeMappingAdjuster: CappedOvertimeMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedOvertimeMappingAdjuster: CappedOvertimeMappingModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedOvertimeMappingAdjuster: CappedOvertimeMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCappedOvertimeMappingAdjuster: CappedOvertimeMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedOvertimeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped overtime mapping steps in order and keeps a trace of each.
    final class CappedOvertimeMappingEngine {
        var steps: [any CappedOvertimeMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOvertimeMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedOvertimeMapping) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [CappedOvertimeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedOvertimeMappingEngine(_ flags: Kit.Flags.Registry) -> CappedOvertimeMappingEngine {
        return CappedOvertimeMappingEngine(
            steps: [
                FlaggedCappedOvertimeMappingAdjuster(
                    flags: flags,
                    flag: "capped-overtime-mapping-tiered",
                    percent: 5.3
                ),
                UnitCappedOvertimeMappingAdjuster(factors: ["north": 0.88, "east": 1.28]),
                PercentCappedOvertimeMappingAdjuster(percent: 7.9),
                MinimumCappedOvertimeMappingAdjuster(minimum: 48.8),
                RoundingCappedOvertimeMappingAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 12927.8
        )
    }
}
