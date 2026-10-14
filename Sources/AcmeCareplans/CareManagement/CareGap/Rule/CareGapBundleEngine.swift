import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap bundle calculation.
    protocol CareGapBundleStep {
        func describe() -> String
        func adjust(_ item: CareGapBundle, value: Double) -> Double
    }

    final class CapCareGapBundleAdjuster: CareGapBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapBundleAdjuster: CareGapBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareGapBundleAdjuster: CareGapBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardCareGapBundleAdjuster: CareGapBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CareGapBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareGapBundleAdjuster: CareGapBundleStep {
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

        func adjust(_ item: CareGapBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap bundle steps in order and keeps a trace of each.
    final class CareGapBundleEngine {
        var steps: [any CareGapBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapBundle) -> Double {
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

        func evaluateAll(_ items: [CareGapBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapBundleEngine(_ flags: Kit.Flags.Registry) -> CareGapBundleEngine {
        return CareGapBundleEngine(
            steps: [
                CapCareGapBundleAdjuster(cap: 38051.0),
                PercentCareGapBundleAdjuster(percent: -8.4),
                MinimumCareGapBundleAdjuster(minimum: 21.9),
                WardCareGapBundleAdjuster(factors: ["west": 1.09]),
                FlaggedCareGapBundleAdjuster(flags: flags, flag: "care-gap-bundle-scheduled", percent: -9.4),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 15251.3
        )
    }
}
