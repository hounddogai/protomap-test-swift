import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary inventory override calculation.
    protocol PrimaryInventoryOverrideFactor {
        func describe() -> String
        func adjust(_ item: PrimaryInventoryOverride, value: Double) -> Double
    }

    final class FlaggedPrimaryInventoryOverrideAdjuster: PrimaryInventoryOverrideFactor {
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

        func adjust(_ item: PrimaryInventoryOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryInventoryOverrideAdjuster: PrimaryInventoryOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryInventoryOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourcePrimaryInventoryOverrideAdjuster: PrimaryInventoryOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PrimaryInventoryOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary inventory override steps in order and keeps a trace of each.
    final class PrimaryInventoryOverrideEngine {
        var steps: [any PrimaryInventoryOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInventoryOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryInventoryOverride) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PrimaryInventoryOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryInventoryOverrideEngine(_ flags: Kit.Flags.Registry) -> PrimaryInventoryOverrideEngine {
        return PrimaryInventoryOverrideEngine(
            steps: [
                FlaggedPrimaryInventoryOverrideAdjuster(
                    flags: flags,
                    flag: "primary-inventory-override-strict",
                    percent: -7.8
                ),
                MinimumPrimaryInventoryOverrideAdjuster(minimum: 14.9),
                SourcePrimaryInventoryOverrideAdjuster(factors: ["south": 1.01, "retail": 1.29]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 82022.5
        )
    }
}
