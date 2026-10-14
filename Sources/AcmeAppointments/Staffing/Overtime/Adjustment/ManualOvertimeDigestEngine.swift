import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual overtime digest calculation.
    protocol ManualOvertimeDigestStep {
        func describe() -> String
        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double
    }

    final class MinimumManualOvertimeDigestAdjuster: ManualOvertimeDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryManualOvertimeDigestAdjuster: ManualOvertimeDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualOvertimeDigestAdjuster: ManualOvertimeDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualOvertimeDigestAdjuster: ManualOvertimeDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualOvertimeDigestAdjuster: ManualOvertimeDigestStep {
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

        func adjust(_ item: ManualOvertimeDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual overtime digest steps in order and keeps a trace of each.
    final class ManualOvertimeDigestEngine {
        var steps: [any ManualOvertimeDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOvertimeDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualOvertimeDigest) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ManualOvertimeDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualOvertimeDigestEngine(_ flags: Kit.Flags.Registry) -> ManualOvertimeDigestEngine {
        return ManualOvertimeDigestEngine(
            steps: [
                MinimumManualOvertimeDigestAdjuster(minimum: 31.3),
                CategoryManualOvertimeDigestAdjuster(factors: ["north": 0.97]),
                PercentManualOvertimeDigestAdjuster(percent: -20.4),
                CapManualOvertimeDigestAdjuster(cap: 17866.0),
                FlaggedManualOvertimeDigestAdjuster(
                    flags: flags,
                    flag: "manual-overtime-digest-lenient",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 91435.6
        )
    }
}
