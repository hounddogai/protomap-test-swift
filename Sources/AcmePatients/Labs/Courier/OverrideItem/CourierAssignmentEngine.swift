import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier assignment calculation.
    protocol CourierAssignmentModifier {
        func describe() -> String
        func adjust(_ item: CourierAssignment, value: Double) -> Double
    }

    final class CapCourierAssignmentAdjuster: CourierAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierAssignmentAdjuster: CourierAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCourierAssignmentAdjuster: CourierAssignmentModifier {
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

        func adjust(_ item: CourierAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCourierAssignmentAdjuster: CourierAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier assignment steps in order and keeps a trace of each.
    final class CourierAssignmentEngine {
        var steps: [any CourierAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierAssignment) -> Double {
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

        func evaluateAll(_ items: [CourierAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierAssignmentEngine(_ flags: Kit.Flags.Registry) -> CourierAssignmentEngine {
        return CourierAssignmentEngine(
            steps: [
                CapCourierAssignmentAdjuster(cap: 46555.0),
                TieredCourierAssignmentAdjuster(bounds: [8787.0, 9198.0, 9891.0], rates: [0.95, 0.88, 1.03]),
                FlaggedCourierAssignmentAdjuster(flags: flags, flag: "courier-assignment-tiered", percent: 2.8),
                PercentCourierAssignmentAdjuster(percent: -16.1),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 27922.6
        )
    }
}
