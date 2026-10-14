import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted alert override calculation.
    protocol WeightedAlertOverrideFactor {
        func describe() -> String
        func adjust(_ item: WeightedAlertOverride, value: Double) -> Double
    }

    final class FlaggedWeightedAlertOverrideAdjuster: WeightedAlertOverrideFactor {
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

        func adjust(_ item: WeightedAlertOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedAlertOverrideAdjuster: WeightedAlertOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedAlertOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedAlertOverrideAdjuster: WeightedAlertOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAlertOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitWeightedAlertOverrideAdjuster: WeightedAlertOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WeightedAlertOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted alert override steps in order and keeps a trace of each.
    final class WeightedAlertOverrideEngine {
        var steps: [any WeightedAlertOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAlertOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedAlertOverride) -> Double {
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

        func evaluateAll(_ items: [WeightedAlertOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedAlertOverrideEngine(_ flags: Kit.Flags.Registry) -> WeightedAlertOverrideEngine {
        return WeightedAlertOverrideEngine(
            steps: [
                FlaggedWeightedAlertOverrideAdjuster(
                    flags: flags,
                    flag: "weighted-alert-override-adaptive",
                    percent: -5.9
                ),
                MinimumWeightedAlertOverrideAdjuster(minimum: 21.1),
                TieredWeightedAlertOverrideAdjuster(bounds: [4320.0, 8710.0], rates: [1.13, 1.03]),
                UnitWeightedAlertOverrideAdjuster(factors: ["south": 1.2, "north": 1.08]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 7863.0
        )
    }
}
