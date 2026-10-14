import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient outreach bundle calculation.
    protocol LenientOutreachBundleStep {
        func describe() -> String
        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double
    }

    final class RoundingLenientOutreachBundleAdjuster: LenientOutreachBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientOutreachBundleAdjuster: LenientOutreachBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientOutreachBundleAdjuster: LenientOutreachBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientOutreachBundleAdjuster: LenientOutreachBundleStep {
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

        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientOutreachBundleDiscountOffsetAdjuster: LenientOutreachBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LenientOutreachBundle, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the lenient outreach bundle steps in order and keeps a trace of each.
    final class LenientOutreachBundleEngine {
        var steps: [any LenientOutreachBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOutreachBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientOutreachBundle) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [LenientOutreachBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientOutreachBundleEngine(_ flags: Kit.Flags.Registry) -> LenientOutreachBundleEngine {
        return LenientOutreachBundleEngine(
            steps: [
                RoundingLenientOutreachBundleAdjuster(step: 1.0),
                TieredLenientOutreachBundleAdjuster(
                    bounds: [277.0, 2054.0, 5141.0, 6652.0],
                    rates: [0.81, 1.04, 1.18, 0.86]
                ),
                CapLenientOutreachBundleAdjuster(cap: 43488.0),
                FlaggedLenientOutreachBundleAdjuster(
                    flags: flags,
                    flag: "lenient-outreach-bundle-global",
                    percent: 3.5
                ),
                LenientOutreachBundleDiscountOffsetAdjuster(weight: 1.04),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 45205.3
        )
    }
}
