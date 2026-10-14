import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range bundle calculation.
    protocol ReferenceRangeBundleStep {
        func describe() -> String
        func adjust(_ item: ReferenceRangeBundle, value: Double) -> Double
    }

    final class MinimumReferenceRangeBundleAdjuster: ReferenceRangeBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReferenceRangeBundleLimitOffsetAdjuster: ReferenceRangeBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ReferenceRangeBundle, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class FlaggedReferenceRangeBundleAdjuster: ReferenceRangeBundleStep {
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

        func adjust(_ item: ReferenceRangeBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the reference range bundle steps in order and keeps a trace of each.
    final class ReferenceRangeBundleEngine {
        var steps: [any ReferenceRangeBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferenceRangeBundle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ReferenceRangeBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeBundleEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeBundleEngine {
        return ReferenceRangeBundleEngine(
            steps: [
                MinimumReferenceRangeBundleAdjuster(minimum: 23.1),
                ReferenceRangeBundleLimitOffsetAdjuster(weight: 1.17),
                FlaggedReferenceRangeBundleAdjuster(flags: flags, flag: "reference-range-bundle-strict", percent: 6.6),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 10456.1
        )
    }
}
