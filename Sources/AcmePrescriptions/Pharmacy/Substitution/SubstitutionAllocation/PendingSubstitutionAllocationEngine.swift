import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending substitution allocation calculation.
    protocol PendingSubstitutionAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double
    }

    final class TieredPendingSubstitutionAllocationAdjuster: PendingSubstitutionAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPendingSubstitutionAllocationAdjuster: PendingSubstitutionAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingSubstitutionAllocationAdjuster: PendingSubstitutionAllocationAdjuster {
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

        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingSubstitutionAllocationWindowDaysOffsetAdjuster: PendingSubstitutionAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapPendingSubstitutionAllocationAdjuster: PendingSubstitutionAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingSubstitutionAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending substitution allocation steps in order and keeps a trace of each.
    final class PendingSubstitutionAllocationEngine {
        var steps: [any PendingSubstitutionAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSubstitutionAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingSubstitutionAllocation) -> Double {
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

        func evaluateAll(_ items: [PendingSubstitutionAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingSubstitutionAllocationEngine(_ flags: Kit.Flags.Registry) -> PendingSubstitutionAllocationEngine {
        return PendingSubstitutionAllocationEngine(
            steps: [
                TieredPendingSubstitutionAllocationAdjuster(
                    bounds: [122.0, 6757.0, 8514.0, 8759.0],
                    rates: [1.2, 0.98, 0.83, 1.11]
                ),
                RoundingPendingSubstitutionAllocationAdjuster(step: 5.0),
                FlaggedPendingSubstitutionAllocationAdjuster(
                    flags: flags,
                    flag: "pending-substitution-allocation-seasonal",
                    percent: -1.3
                ),
                PendingSubstitutionAllocationWindowDaysOffsetAdjuster(weight: 1.0),
                CapPendingSubstitutionAllocationAdjuster(cap: 45740.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 64402.3
        )
    }
}
