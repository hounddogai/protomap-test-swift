import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime allocation calculation.
    protocol OvertimeAllocationFactor {
        func describe() -> String
        func adjust(_ item: OvertimeAllocation, value: Double) -> Double
    }

    final class PercentOvertimeAllocationAdjuster: OvertimeAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OvertimeAllocationFloorValueOffsetAdjuster: OvertimeAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingOvertimeAllocationAdjuster: OvertimeAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityOvertimeAllocationAdjuster: OvertimeAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOvertimeAllocationAdjuster: OvertimeAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedOvertimeAllocationAdjuster: OvertimeAllocationFactor {
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

        func adjust(_ item: OvertimeAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime allocation steps in order and keeps a trace of each.
    final class OvertimeAllocationEngine {
        var steps: [any OvertimeAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OvertimeAllocation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [OvertimeAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOvertimeAllocationEngine(_ flags: Kit.Flags.Registry) -> OvertimeAllocationEngine {
        return OvertimeAllocationEngine(
            steps: [
                PercentOvertimeAllocationAdjuster(percent: 17.2),
                OvertimeAllocationFloorValueOffsetAdjuster(weight: 1.14),
                RoundingOvertimeAllocationAdjuster(step: 1.0),
                FacilityOvertimeAllocationAdjuster(factors: ["north": 1.17, "central": 0.99]),
                TieredOvertimeAllocationAdjuster(
                    bounds: [2311.0, 3566.0, 8016.0, 9551.0],
                    rates: [1.11, 0.87, 0.97, 1.19]
                ),
                FlaggedOvertimeAllocationAdjuster(flags: flags, flag: "overtime-allocation-legacy", percent: -8.2),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 43618.2
        )
    }
}
