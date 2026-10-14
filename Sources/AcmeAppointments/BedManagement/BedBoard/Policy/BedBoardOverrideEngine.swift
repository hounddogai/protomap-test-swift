import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board override calculation.
    protocol BedBoardOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardOverride, value: Double) -> Double
    }

    final class MinimumBedBoardOverrideAdjuster: BedBoardOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BedBoardOverrideThresholdOffsetAdjuster: BedBoardOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class WardBedBoardOverrideAdjuster: BedBoardOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBedBoardOverrideAdjuster: BedBoardOverrideAdjuster {
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

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBedBoardOverrideAdjuster: BedBoardOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBedBoardOverrideAdjuster: BedBoardOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board override steps in order and keeps a trace of each.
    final class BedBoardOverrideEngine {
        var steps: [any BedBoardOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BedBoardOverride) -> Double {
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

        func evaluateAll(_ items: [BedBoardOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBedBoardOverrideEngine(_ flags: Kit.Flags.Registry) -> BedBoardOverrideEngine {
        return BedBoardOverrideEngine(
            steps: [
                MinimumBedBoardOverrideAdjuster(minimum: 46.9),
                BedBoardOverrideThresholdOffsetAdjuster(weight: 0.24),
                WardBedBoardOverrideAdjuster(factors: ["retail": 1.16]),
                FlaggedBedBoardOverrideAdjuster(flags: flags, flag: "bed-board-override-pending", percent: -4.8),
                TieredBedBoardOverrideAdjuster(
                    bounds: [990.0, 1477.0, 5988.0, 6743.0],
                    rates: [0.96, 1.15, 1.15, 1.2]
                ),
                PercentBedBoardOverrideAdjuster(percent: 12.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 85854.2
        )
    }
}
