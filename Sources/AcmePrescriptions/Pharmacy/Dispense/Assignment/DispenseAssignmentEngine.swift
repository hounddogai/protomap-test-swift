import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense assignment calculation.
    protocol DispenseAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseAssignment, value: Double) -> Double
    }

    final class RoundingDispenseAssignmentAdjuster: DispenseAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDispenseAssignmentAdjuster: DispenseAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityDispenseAssignmentAdjuster: DispenseAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DispenseAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDispenseAssignmentAdjuster: DispenseAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDispenseAssignmentAdjuster: DispenseAssignmentAdjuster {
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

        func adjust(_ item: DispenseAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense assignment steps in order and keeps a trace of each.
    final class DispenseAssignmentEngine {
        var steps: [any DispenseAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseAssignment) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [DispenseAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseAssignmentEngine(_ flags: Kit.Flags.Registry) -> DispenseAssignmentEngine {
        return DispenseAssignmentEngine(
            steps: [
                RoundingDispenseAssignmentAdjuster(step: 5.0),
                CapDispenseAssignmentAdjuster(cap: 3774.0),
                FacilityDispenseAssignmentAdjuster(factors: ["east": 1.13, "west": 0.9]),
                PercentDispenseAssignmentAdjuster(percent: 17.9),
                FlaggedDispenseAssignmentAdjuster(flags: flags, flag: "dispense-assignment-lenient", percent: 3.3),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 4908.1
        )
    }
}
