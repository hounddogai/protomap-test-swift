import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary reference range bundle calculation.
    protocol PrimaryReferenceRangeBundleAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double
    }

    final class PrimaryReferenceRangeBundleStartsAtOffsetAdjuster: PrimaryReferenceRangeBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredPrimaryReferenceRangeBundleAdjuster: PrimaryReferenceRangeBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelPrimaryReferenceRangeBundleAdjuster: PrimaryReferenceRangeBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryReferenceRangeBundleAdjuster: PrimaryReferenceRangeBundleAdjuster {
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

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryReferenceRangeBundleAdjuster: PrimaryReferenceRangeBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryReferenceRangeBundleAdjuster: PrimaryReferenceRangeBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryReferenceRangeBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary reference range bundle steps in order and keeps a trace of each.
    final class PrimaryReferenceRangeBundleEngine {
        var steps: [any PrimaryReferenceRangeBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReferenceRangeBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryReferenceRangeBundle) -> Double {
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

        func evaluateAll(_ items: [PrimaryReferenceRangeBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryReferenceRangeBundleEngine(_ flags: Kit.Flags.Registry) -> PrimaryReferenceRangeBundleEngine {
        return PrimaryReferenceRangeBundleEngine(
            steps: [
                PrimaryReferenceRangeBundleStartsAtOffsetAdjuster(weight: 0.75),
                TieredPrimaryReferenceRangeBundleAdjuster(bounds: [1065.0, 5311.0], rates: [0.8, 0.99]),
                ChannelPrimaryReferenceRangeBundleAdjuster(factors: ["north": 1.39, "west": 0.97]),
                FlaggedPrimaryReferenceRangeBundleAdjuster(
                    flags: flags,
                    flag: "primary-reference-range-bundle-seasonal",
                    percent: 0.2
                ),
                MinimumPrimaryReferenceRangeBundleAdjuster(minimum: 41.1),
                CapPrimaryReferenceRangeBundleAdjuster(cap: 46710.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 12844.6
        )
    }
}
