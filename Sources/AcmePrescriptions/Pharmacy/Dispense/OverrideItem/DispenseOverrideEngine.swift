import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense override calculation.
    protocol DispenseOverrideModifier {
        func describe() -> String
        func adjust(_ item: DispenseOverride, value: Double) -> Double
    }

    final class FlaggedDispenseOverrideAdjuster: DispenseOverrideModifier {
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

        func adjust(_ item: DispenseOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDispenseOverrideAdjuster: DispenseOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelDispenseOverrideAdjuster: DispenseOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DispenseOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DispenseOverrideDiscountOffsetAdjuster: DispenseOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: DispenseOverride, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentDispenseOverrideAdjuster: DispenseOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense override steps in order and keeps a trace of each.
    final class DispenseOverrideEngine {
        var steps: [any DispenseOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseOverride) -> Double {
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

        func evaluateAll(_ items: [DispenseOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseOverrideEngine(_ flags: Kit.Flags.Registry) -> DispenseOverrideEngine {
        return DispenseOverrideEngine(
            steps: [
                FlaggedDispenseOverrideAdjuster(flags: flags, flag: "dispense-override-regional", percent: -8.3),
                TieredDispenseOverrideAdjuster(bounds: [4394.0, 4908.0], rates: [0.9, 1.09]),
                LabelDispenseOverrideAdjuster(factors: ["west": 0.98, "online": 0.7, "retail": 1.25]),
                DispenseOverrideDiscountOffsetAdjuster(weight: 0.32),
                PercentDispenseOverrideAdjuster(percent: 0.7),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 98266.0
        )
    }
}
