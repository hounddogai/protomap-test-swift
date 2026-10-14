import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense quota calculation.
    protocol DispenseQuotaModifier {
        func describe() -> String
        func adjust(_ item: DispenseQuota, value: Double) -> Double
    }

    final class FlaggedDispenseQuotaAdjuster: DispenseQuotaModifier {
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

        func adjust(_ item: DispenseQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDispenseQuotaAdjuster: DispenseQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDispenseQuotaAdjuster: DispenseQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the dispense quota steps in order and keeps a trace of each.
    final class DispenseQuotaEngine {
        var steps: [any DispenseQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseQuota) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [DispenseQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseQuotaEngine(_ flags: Kit.Flags.Registry) -> DispenseQuotaEngine {
        return DispenseQuotaEngine(
            steps: [
                FlaggedDispenseQuotaAdjuster(flags: flags, flag: "dispense-quota-pending", percent: 6.5),
                CapDispenseQuotaAdjuster(cap: 47441.0),
                MinimumDispenseQuotaAdjuster(minimum: 1.7),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 5834.7
        )
    }
}
