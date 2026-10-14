import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense audit calculation.
    protocol DispenseAuditStep {
        func describe() -> String
        func adjust(_ item: DispenseAudit, value: Double) -> Double
    }

    final class RoundingDispenseAuditAdjuster: DispenseAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DispenseAuditCreatedAtOffsetAdjuster: DispenseAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class CapDispenseAuditAdjuster: DispenseAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDispenseAuditAdjuster: DispenseAuditStep {
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

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardDispenseAuditAdjuster: DispenseAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDispenseAuditAdjuster: DispenseAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the dispense audit steps in order and keeps a trace of each.
    final class DispenseAuditEngine {
        var steps: [any DispenseAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DispenseAudit) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseAuditStep = steps[index]
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

        func evaluateAll(_ items: [DispenseAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDispenseAuditEngine(_ flags: Kit.Flags.Registry) -> DispenseAuditEngine {
        return DispenseAuditEngine(
            steps: [
                RoundingDispenseAuditAdjuster(step: 0.25),
                DispenseAuditCreatedAtOffsetAdjuster(weight: 1.79),
                CapDispenseAuditAdjuster(cap: 6908.0),
                FlaggedDispenseAuditAdjuster(flags: flags, flag: "dispense-audit-global", percent: -2.5),
                WardDispenseAuditAdjuster(factors: ["north": 1.13, "retail": 1.32]),
                MinimumDispenseAuditAdjuster(minimum: 3.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 47974.2
        )
    }
}
