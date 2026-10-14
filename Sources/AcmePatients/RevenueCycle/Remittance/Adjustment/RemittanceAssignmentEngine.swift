import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance assignment calculation.
    protocol RemittanceAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceAssignment, value: Double) -> Double
    }

    final class FlaggedRemittanceAssignmentAdjuster: RemittanceAssignmentAdjuster {
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

        func adjust(_ item: RemittanceAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRemittanceAssignmentAdjuster: RemittanceAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRemittanceAssignmentAdjuster: RemittanceAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance assignment steps in order and keeps a trace of each.
    final class RemittanceAssignmentEngine {
        var steps: [any RemittanceAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceAssignment) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RemittanceAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceAssignmentEngine(_ flags: Kit.Flags.Registry) -> RemittanceAssignmentEngine {
        return RemittanceAssignmentEngine(
            steps: [
                FlaggedRemittanceAssignmentAdjuster(flags: flags, flag: "remittance-assignment-tiered", percent: 5.7),
                RoundingRemittanceAssignmentAdjuster(step: 5.0),
                PercentRemittanceAssignmentAdjuster(percent: 7.9),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 42183.5
        )
    }
}
