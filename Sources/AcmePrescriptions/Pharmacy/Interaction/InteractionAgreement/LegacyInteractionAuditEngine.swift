import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy interaction audit calculation.
    protocol LegacyInteractionAuditModifier {
        func describe() -> String
        func adjust(_ item: LegacyInteractionAudit, value: Double) -> Double
    }

    final class CapLegacyInteractionAuditAdjuster: LegacyInteractionAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyInteractionAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyInteractionAuditCapacityOffsetAdjuster: LegacyInteractionAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: LegacyInteractionAudit, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumLegacyInteractionAuditAdjuster: LegacyInteractionAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInteractionAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy interaction audit steps in order and keeps a trace of each.
    final class LegacyInteractionAuditEngine {
        var steps: [any LegacyInteractionAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInteractionAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyInteractionAudit) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyInteractionAuditModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyInteractionAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyInteractionAuditEngine() -> LegacyInteractionAuditEngine {
        return LegacyInteractionAuditEngine(
            steps: [
                CapLegacyInteractionAuditAdjuster(cap: 21783.0),
                LegacyInteractionAuditCapacityOffsetAdjuster(weight: 1.04),
                MinimumLegacyInteractionAuditAdjuster(minimum: 48.2),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 74176.4
        )
    }
}
