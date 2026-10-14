import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary credential allocation calculation.
    protocol PrimaryCredentialAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double
    }

    final class MinimumPrimaryCredentialAllocationAdjuster: PrimaryCredentialAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryCredentialAllocationCapacityOffsetAdjuster: PrimaryCredentialAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingPrimaryCredentialAllocationAdjuster: PrimaryCredentialAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimaryCredentialAllocationAdjuster: PrimaryCredentialAllocationAdjuster {
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

        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryCredentialAllocationAdjuster: PrimaryCredentialAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCredentialAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary credential allocation steps in order and keeps a trace of each.
    final class PrimaryCredentialAllocationEngine {
        var steps: [any PrimaryCredentialAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCredentialAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryCredentialAllocation) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [PrimaryCredentialAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryCredentialAllocationEngine(_ flags: Kit.Flags.Registry) -> PrimaryCredentialAllocationEngine {
        return PrimaryCredentialAllocationEngine(
            steps: [
                MinimumPrimaryCredentialAllocationAdjuster(minimum: 29.9),
                PrimaryCredentialAllocationCapacityOffsetAdjuster(weight: 0.56),
                RoundingPrimaryCredentialAllocationAdjuster(step: 0.25),
                FlaggedPrimaryCredentialAllocationAdjuster(
                    flags: flags,
                    flag: "primary-credential-allocation-primary",
                    percent: 8.9
                ),
                PercentPrimaryCredentialAllocationAdjuster(percent: 3.7),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 29814.8
        )
    }
}
