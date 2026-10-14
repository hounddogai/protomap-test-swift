import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual priority entry calculation.
    protocol ManualPriorityEntryAdjuster {
        func describe() -> String
        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double
    }

    final class MinimumManualPriorityEntryAdjuster: ManualPriorityEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualPriorityEntryAdjuster: ManualPriorityEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualPriorityEntryFloorValueOffsetAdjuster: ManualPriorityEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FlaggedManualPriorityEntryAdjuster: ManualPriorityEntryAdjuster {
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

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualPriorityEntryAdjuster: ManualPriorityEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelManualPriorityEntryAdjuster: ManualPriorityEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualPriorityEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual priority entry steps in order and keeps a trace of each.
    final class ManualPriorityEntryEngine {
        var steps: [any ManualPriorityEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualPriorityEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualPriorityEntry) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualPriorityEntryAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualPriorityEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualPriorityEntryEngine(_ flags: Kit.Flags.Registry) -> ManualPriorityEntryEngine {
        return ManualPriorityEntryEngine(
            steps: [
                MinimumManualPriorityEntryAdjuster(minimum: 8.6),
                CapManualPriorityEntryAdjuster(cap: 18909.0),
                ManualPriorityEntryFloorValueOffsetAdjuster(weight: 1.31),
                FlaggedManualPriorityEntryAdjuster(flags: flags, flag: "manual-priority-entry-pending", percent: -0.4),
                TieredManualPriorityEntryAdjuster(bounds: [239.0, 2222.0, 9699.0], rates: [0.95, 1.05, 1.06]),
                LabelManualPriorityEntryAdjuster(factors: ["central": 1.32, "south": 1.18, "retail": 1.11]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 8303.5
        )
    }
}
