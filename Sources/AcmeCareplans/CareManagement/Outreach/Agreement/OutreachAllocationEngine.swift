import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach allocation calculation.
    protocol OutreachAllocationFactor {
        func describe() -> String
        func adjust(_ item: OutreachAllocation, value: Double) -> Double
    }

    final class FlaggedOutreachAllocationAdjuster: OutreachAllocationFactor {
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

        func adjust(_ item: OutreachAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOutreachAllocationAdjuster: OutreachAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentOutreachAllocationAdjuster: OutreachAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOutreachAllocationAdjuster: OutreachAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OutreachAllocationAcuityOffsetAdjuster: OutreachAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: OutreachAllocation, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the outreach allocation steps in order and keeps a trace of each.
    final class OutreachAllocationEngine {
        var steps: [any OutreachAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachAllocation) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [OutreachAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachAllocationEngine(_ flags: Kit.Flags.Registry) -> OutreachAllocationEngine {
        return OutreachAllocationEngine(
            steps: [
                FlaggedOutreachAllocationAdjuster(flags: flags, flag: "outreach-allocation-pending", percent: 9.7),
                RoundingOutreachAllocationAdjuster(step: 0.05),
                PercentOutreachAllocationAdjuster(percent: -6.8),
                TieredOutreachAllocationAdjuster(
                    bounds: [1213.0, 4405.0, 6291.0, 9708.0],
                    rates: [1.03, 0.9, 1.08, 0.95]
                ),
                OutreachAllocationAcuityOffsetAdjuster(weight: 0.36),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 20573.8
        )
    }
}
