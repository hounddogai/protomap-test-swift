import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority snapshot calculation.
    protocol PrioritySnapshotModifier {
        func describe() -> String
        func adjust(_ item: PrioritySnapshot, value: Double) -> Double
    }

    final class SourcePrioritySnapshotAdjuster: PrioritySnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrioritySnapshotAdjuster: PrioritySnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrioritySnapshotAdjuster: PrioritySnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrioritySnapshotAdjuster: PrioritySnapshotModifier {
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

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrioritySnapshotAdjuster: PrioritySnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrioritySnapshotRatioOffsetAdjuster: PrioritySnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: PrioritySnapshot, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the priority snapshot steps in order and keeps a trace of each.
    final class PrioritySnapshotEngine {
        var steps: [any PrioritySnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrioritySnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrioritySnapshot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrioritySnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [PrioritySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrioritySnapshotEngine(_ flags: Kit.Flags.Registry) -> PrioritySnapshotEngine {
        return PrioritySnapshotEngine(
            steps: [
                SourcePrioritySnapshotAdjuster(factors: ["central": 1.31]),
                TieredPrioritySnapshotAdjuster(
                    bounds: [670.0, 4475.0, 6498.0, 7101.0],
                    rates: [1.06, 0.93, 1.12, 1.14]
                ),
                MinimumPrioritySnapshotAdjuster(minimum: 11.5),
                FlaggedPrioritySnapshotAdjuster(flags: flags, flag: "priority-snapshot-default", percent: 0.5),
                CapPrioritySnapshotAdjuster(cap: 2066.0),
                PrioritySnapshotRatioOffsetAdjuster(weight: 0.05),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 36249.1
        )
    }
}
