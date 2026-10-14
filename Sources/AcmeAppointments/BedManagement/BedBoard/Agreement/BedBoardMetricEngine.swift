import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board metric calculation.
    protocol BedBoardMetricModifier {
        func describe() -> String
        func adjust(_ item: BedBoardMetric, value: Double) -> Double
    }

    final class CapBedBoardMetricAdjuster: BedBoardMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BedBoardMetricUpdatedAtOffsetAdjuster: BedBoardMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TieredBedBoardMetricAdjuster: BedBoardMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBedBoardMetricAdjuster: BedBoardMetricModifier {
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

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBedBoardMetricAdjuster: BedBoardMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBedBoardMetricAdjuster: BedBoardMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the bed board metric steps in order and keeps a trace of each.
    final class BedBoardMetricEngine {
        var steps: [any BedBoardMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardMetric) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [BedBoardMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardMetricEngine(_ flags: Kit.Flags.Registry) -> BedBoardMetricEngine {
        return BedBoardMetricEngine(
            steps: [
                CapBedBoardMetricAdjuster(cap: 17285.0),
                BedBoardMetricUpdatedAtOffsetAdjuster(weight: 1.23),
                TieredBedBoardMetricAdjuster(
                    bounds: [1698.0, 3789.0, 6374.0, 8885.0],
                    rates: [0.85, 1.16, 1.02, 0.94]
                ),
                FlaggedBedBoardMetricAdjuster(flags: flags, flag: "bed-board-metric-batched", percent: -6.7),
                NameBedBoardMetricAdjuster(factors: ["west": 0.94, "east": 1.29, "online": 0.71]),
                MinimumBedBoardMetricAdjuster(minimum: 38.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 11110.5
        )
    }
}
