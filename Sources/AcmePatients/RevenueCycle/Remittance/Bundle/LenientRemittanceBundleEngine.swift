import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient remittance bundle calculation.
    protocol LenientRemittanceBundleFactor {
        func describe() -> String
        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double
    }

    final class FlaggedLenientRemittanceBundleAdjuster: LenientRemittanceBundleFactor {
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

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientRemittanceBundleAdjuster: LenientRemittanceBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientRemittanceBundleAmountOffsetAdjuster: LenientRemittanceBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentLenientRemittanceBundleAdjuster: LenientRemittanceBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientRemittanceBundleAdjuster: LenientRemittanceBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLenientRemittanceBundleAdjuster: LenientRemittanceBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientRemittanceBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient remittance bundle steps in order and keeps a trace of each.
    final class LenientRemittanceBundleEngine {
        var steps: [any LenientRemittanceBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRemittanceBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientRemittanceBundle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRemittanceBundleFactor = steps[index]
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

        func evaluateAll(_ items: [LenientRemittanceBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientRemittanceBundleEngine(_ flags: Kit.Flags.Registry) -> LenientRemittanceBundleEngine {
        return LenientRemittanceBundleEngine(
            steps: [
                FlaggedLenientRemittanceBundleAdjuster(
                    flags: flags,
                    flag: "lenient-remittance-bundle-capped",
                    percent: 3.5
                ),
                RoundingLenientRemittanceBundleAdjuster(step: 5.0),
                LenientRemittanceBundleAmountOffsetAdjuster(weight: 0.52),
                PercentLenientRemittanceBundleAdjuster(percent: -10.9),
                TieredLenientRemittanceBundleAdjuster(
                    bounds: [5779.0, 6405.0, 9081.0, 9242.0],
                    rates: [0.94, 0.82, 0.99, 0.93]
                ),
                TitleLenientRemittanceBundleAdjuster(factors: ["retail": 0.71, "central": 0.98, "north": 1.1]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 66848.6
        )
    }
}
