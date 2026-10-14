import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict witness audit calculation.
    protocol StrictWitnessAuditAdjuster {
        func describe() -> String
        func adjust(_ item: StrictWitnessAudit, value: Double) -> Double
    }

    final class MinimumStrictWitnessAuditAdjuster: StrictWitnessAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictWitnessAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictWitnessAuditAdjuster: StrictWitnessAuditAdjuster {
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

        func adjust(_ item: StrictWitnessAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictWitnessAuditUpdatedAtOffsetAdjuster: StrictWitnessAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: StrictWitnessAudit, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the strict witness audit steps in order and keeps a trace of each.
    final class StrictWitnessAuditEngine {
        var steps: [any StrictWitnessAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWitnessAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictWitnessAudit) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictWitnessAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictWitnessAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictWitnessAuditEngine(_ flags: Kit.Flags.Registry) -> StrictWitnessAuditEngine {
        return StrictWitnessAuditEngine(
            steps: [
                MinimumStrictWitnessAuditAdjuster(minimum: 42.9),
                FlaggedStrictWitnessAuditAdjuster(flags: flags, flag: "strict-witness-audit-pending", percent: -2.9),
                StrictWitnessAuditUpdatedAtOffsetAdjuster(weight: 0.35),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 20439.6
        )
    }
}
