import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global outreach allocation calculation.
    protocol GlobalOutreachAllocationModifier {
        func describe() -> String
        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double
    }

    final class PercentGlobalOutreachAllocationAdjuster: GlobalOutreachAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalOutreachAllocationAdjuster: GlobalOutreachAllocationModifier {
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

        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalOutreachAllocationAdjuster: GlobalOutreachAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalOutreachAllocationAdjuster: GlobalOutreachAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalOutreachAllocationAdjuster: GlobalOutreachAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalOutreachAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global outreach allocation steps in order and keeps a trace of each.
    final class GlobalOutreachAllocationEngine {
        var steps: [any GlobalOutreachAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOutreachAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalOutreachAllocation) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [GlobalOutreachAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalOutreachAllocationEngine(_ flags: Kit.Flags.Registry) -> GlobalOutreachAllocationEngine {
        return GlobalOutreachAllocationEngine(
            steps: [
                PercentGlobalOutreachAllocationAdjuster(percent: -3.2),
                FlaggedGlobalOutreachAllocationAdjuster(
                    flags: flags,
                    flag: "global-outreach-allocation-adaptive",
                    percent: 3.8
                ),
                TieredGlobalOutreachAllocationAdjuster(bounds: [1132.0, 6208.0, 8099.0], rates: [1.11, 1.08, 0.9]),
                CapGlobalOutreachAllocationAdjuster(cap: 16600.0),
                RoundingGlobalOutreachAllocationAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 73493.7
        )
    }
}
