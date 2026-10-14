import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff quota calculation.
    protocol HandoffQuotaModifier {
        func describe() -> String
        func adjust(_ item: HandoffQuota, value: Double) -> Double
    }

    final class PercentHandoffQuotaAdjuster: HandoffQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameHandoffQuotaAdjuster: HandoffQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumHandoffQuotaAdjuster: HandoffQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedHandoffQuotaAdjuster: HandoffQuotaModifier {
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

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapHandoffQuotaAdjuster: HandoffQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class HandoffQuotaExpiresAtOffsetAdjuster: HandoffQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: HandoffQuota, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the handoff quota steps in order and keeps a trace of each.
    final class HandoffQuotaEngine {
        var steps: [any HandoffQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [HandoffQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffQuotaEngine(_ flags: Kit.Flags.Registry) -> HandoffQuotaEngine {
        return HandoffQuotaEngine(
            steps: [
                PercentHandoffQuotaAdjuster(percent: 0.5),
                NameHandoffQuotaAdjuster(factors: ["west": 1.01, "retail": 0.79, "north": 1.17]),
                MinimumHandoffQuotaAdjuster(minimum: 41.3),
                FlaggedHandoffQuotaAdjuster(flags: flags, flag: "handoff-quota-pending", percent: -3.4),
                CapHandoffQuotaAdjuster(cap: 38004.0),
                HandoffQuotaExpiresAtOffsetAdjuster(weight: 1.13),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 80182.2
        )
    }
}
