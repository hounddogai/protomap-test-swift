import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global transfer assignment calculation.
    protocol GlobalTransferAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalTransferAssignment, value: Double) -> Double
    }

    final class GlobalTransferAssignmentCapacityOffsetAdjuster: GlobalTransferAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: GlobalTransferAssignment, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentGlobalTransferAssignmentAdjuster: GlobalTransferAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalTransferAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalTransferAssignmentAdjuster: GlobalTransferAssignmentAdjuster {
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

        func adjust(_ item: GlobalTransferAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitGlobalTransferAssignmentAdjuster: GlobalTransferAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GlobalTransferAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global transfer assignment steps in order and keeps a trace of each.
    final class GlobalTransferAssignmentEngine {
        var steps: [any GlobalTransferAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalTransferAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalTransferAssignment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalTransferAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalTransferAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalTransferAssignmentEngine(_ flags: Kit.Flags.Registry) -> GlobalTransferAssignmentEngine {
        return GlobalTransferAssignmentEngine(
            steps: [
                GlobalTransferAssignmentCapacityOffsetAdjuster(weight: 0.07),
                PercentGlobalTransferAssignmentAdjuster(percent: 16.7),
                FlaggedGlobalTransferAssignmentAdjuster(
                    flags: flags,
                    flag: "global-transfer-assignment-seasonal",
                    percent: -1.6
                ),
                UnitGlobalTransferAssignmentAdjuster(factors: ["online": 1.16, "north": 1.03]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 33818.5
        )
    }
}
