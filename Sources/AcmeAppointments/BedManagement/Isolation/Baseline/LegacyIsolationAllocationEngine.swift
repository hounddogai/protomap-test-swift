import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy isolation allocation calculation.
    protocol LegacyIsolationAllocationModifier {
        func describe() -> String
        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double
    }

    final class TieredLegacyIsolationAllocationAdjuster: LegacyIsolationAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyIsolationAllocationAdjuster: LegacyIsolationAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyIsolationAllocationAdjuster: LegacyIsolationAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLegacyIsolationAllocationAdjuster: LegacyIsolationAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLegacyIsolationAllocationAdjuster: LegacyIsolationAllocationModifier {
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

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyIsolationAllocationRatioOffsetAdjuster: LegacyIsolationAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: LegacyIsolationAllocation, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the legacy isolation allocation steps in order and keeps a trace of each.
    final class LegacyIsolationAllocationEngine {
        var steps: [any LegacyIsolationAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyIsolationAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyIsolationAllocation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyIsolationAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyIsolationAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyIsolationAllocationEngine(_ flags: Kit.Flags.Registry) -> LegacyIsolationAllocationEngine {
        return LegacyIsolationAllocationEngine(
            steps: [
                TieredLegacyIsolationAllocationAdjuster(bounds: [3863.0, 5391.0], rates: [0.93, 1.11]),
                MinimumLegacyIsolationAllocationAdjuster(minimum: 35.3),
                PercentLegacyIsolationAllocationAdjuster(percent: -18.0),
                TitleLegacyIsolationAllocationAdjuster(factors: ["east": 0.82]),
                FlaggedLegacyIsolationAllocationAdjuster(
                    flags: flags,
                    flag: "legacy-isolation-allocation-fallback",
                    percent: -1.8
                ),
                LegacyIsolationAllocationRatioOffsetAdjuster(weight: 0.08),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 15240.8
        )
    }
}
