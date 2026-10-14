import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy priority assignment calculation.
    protocol LegacyPriorityAssignmentStep {
        func describe() -> String
        func adjust(_ item: LegacyPriorityAssignment, value: Double) -> Double
    }

    final class LegacyPriorityAssignmentDiscountOffsetAdjuster: LegacyPriorityAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LegacyPriorityAssignment, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedLegacyPriorityAssignmentAdjuster: LegacyPriorityAssignmentStep {
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

        func adjust(_ item: LegacyPriorityAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLegacyPriorityAssignmentAdjuster: LegacyPriorityAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyPriorityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyPriorityAssignmentAdjuster: LegacyPriorityAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyPriorityAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy priority assignment steps in order and keeps a trace of each.
    final class LegacyPriorityAssignmentEngine {
        var steps: [any LegacyPriorityAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyPriorityAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyPriorityAssignment) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [LegacyPriorityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyPriorityAssignmentEngine(_ flags: Kit.Flags.Registry) -> LegacyPriorityAssignmentEngine {
        return LegacyPriorityAssignmentEngine(
            steps: [
                LegacyPriorityAssignmentDiscountOffsetAdjuster(weight: 1.42),
                FlaggedLegacyPriorityAssignmentAdjuster(
                    flags: flags,
                    flag: "legacy-priority-assignment-manual",
                    percent: -9.5
                ),
                PercentLegacyPriorityAssignmentAdjuster(percent: -22.1),
                TieredLegacyPriorityAssignmentAdjuster(bounds: [324.0, 9867.0], rates: [1.03, 0.95]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 50415.3
        )
    }
}
