import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan allocation calculation.
    protocol AcuityPlanAllocationModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double
    }

    final class FlaggedAcuityPlanAllocationAdjuster: AcuityPlanAllocationModifier {
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

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAcuityPlanAllocationAdjuster: AcuityPlanAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AcuityPlanAllocationQuantityOffsetAdjuster: AcuityPlanAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentAcuityPlanAllocationAdjuster: AcuityPlanAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionAcuityPlanAllocationAdjuster: AcuityPlanAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAcuityPlanAllocationAdjuster: AcuityPlanAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan allocation steps in order and keeps a trace of each.
    final class AcuityPlanAllocationEngine {
        var steps: [any AcuityPlanAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanAllocation) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanAllocationEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanAllocationEngine {
        return AcuityPlanAllocationEngine(
            steps: [
                FlaggedAcuityPlanAllocationAdjuster(
                    flags: flags,
                    flag: "acuity-plan-allocation-adaptive",
                    percent: 0.2
                ),
                RoundingAcuityPlanAllocationAdjuster(step: 0.05),
                AcuityPlanAllocationQuantityOffsetAdjuster(weight: 0.84),
                PercentAcuityPlanAllocationAdjuster(percent: 9.0),
                RegionAcuityPlanAllocationAdjuster(factors: ["east": 1.14, "north": 1.09]),
                CapAcuityPlanAllocationAdjuster(cap: 38265.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 94879.1
        )
    }
}
