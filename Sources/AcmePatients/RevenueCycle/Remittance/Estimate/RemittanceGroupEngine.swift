import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance group calculation.
    protocol RemittanceGroupFactor {
        func describe() -> String
        func adjust(_ item: RemittanceGroup, value: Double) -> Double
    }

    final class RoundingRemittanceGroupAdjuster: RemittanceGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRemittanceGroupAdjuster: RemittanceGroupFactor {
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

        func adjust(_ item: RemittanceGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRemittanceGroupAdjuster: RemittanceGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceGroupAdjuster: RemittanceGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRemittanceGroupAdjuster: RemittanceGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance group steps in order and keeps a trace of each.
    final class RemittanceGroupEngine {
        var steps: [any RemittanceGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceGroup) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RemittanceGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceGroupEngine(_ flags: Kit.Flags.Registry) -> RemittanceGroupEngine {
        return RemittanceGroupEngine(
            steps: [
                RoundingRemittanceGroupAdjuster(step: 0.1),
                FlaggedRemittanceGroupAdjuster(flags: flags, flag: "remittance-group-scheduled", percent: -2.9),
                PercentRemittanceGroupAdjuster(percent: -8.1),
                MinimumRemittanceGroupAdjuster(minimum: 17.7),
                CapRemittanceGroupAdjuster(cap: 9959.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 24834.1
        )
    }
}
