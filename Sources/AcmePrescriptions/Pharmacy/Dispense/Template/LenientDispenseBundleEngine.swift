import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient dispense bundle calculation.
    protocol LenientDispenseBundleModifier {
        func describe() -> String
        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double
    }

    final class PercentLenientDispenseBundleAdjuster: LenientDispenseBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientDispenseBundleAdjuster: LenientDispenseBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientDispenseBundleDiscountOffsetAdjuster: LenientDispenseBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CountryLenientDispenseBundleAdjuster: LenientDispenseBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientDispenseBundleAdjuster: LenientDispenseBundleModifier {
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

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientDispenseBundleAdjuster: LenientDispenseBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDispenseBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient dispense bundle steps in order and keeps a trace of each.
    final class LenientDispenseBundleEngine {
        var steps: [any LenientDispenseBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDispenseBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientDispenseBundle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDispenseBundleModifier = steps[index]
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

        func evaluateAll(_ items: [LenientDispenseBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientDispenseBundleEngine(_ flags: Kit.Flags.Registry) -> LenientDispenseBundleEngine {
        return LenientDispenseBundleEngine(
            steps: [
                PercentLenientDispenseBundleAdjuster(percent: 5.7),
                CapLenientDispenseBundleAdjuster(cap: 3766.0),
                LenientDispenseBundleDiscountOffsetAdjuster(weight: 1.57),
                CountryLenientDispenseBundleAdjuster(factors: ["south": 0.89]),
                FlaggedLenientDispenseBundleAdjuster(
                    flags: flags,
                    flag: "lenient-dispense-bundle-pending",
                    percent: -3.4
                ),
                RoundingLenientDispenseBundleAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 30491.2
        )
    }
}
