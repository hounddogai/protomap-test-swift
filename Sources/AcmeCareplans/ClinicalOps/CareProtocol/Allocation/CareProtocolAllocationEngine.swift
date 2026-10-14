import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol allocation calculation.
    protocol CareProtocolAllocationStep {
        func describe() -> String
        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double
    }

    final class MinimumCareProtocolAllocationAdjuster: CareProtocolAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareProtocolAllocationAdjuster: CareProtocolAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCareProtocolAllocationAdjuster: CareProtocolAllocationStep {
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

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityCareProtocolAllocationAdjuster: CareProtocolAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareProtocolAllocationRateOffsetAdjuster: CareProtocolAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the care protocol allocation steps in order and keeps a trace of each.
    final class CareProtocolAllocationEngine {
        var steps: [any CareProtocolAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolAllocation) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolAllocationStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAllocationEngine(_ flags: Kit.Flags.Registry) -> CareProtocolAllocationEngine {
        return CareProtocolAllocationEngine(
            steps: [
                MinimumCareProtocolAllocationAdjuster(minimum: 37.3),
                RoundingCareProtocolAllocationAdjuster(step: 5.0),
                FlaggedCareProtocolAllocationAdjuster(
                    flags: flags,
                    flag: "care-protocol-allocation-primary",
                    percent: 3.6
                ),
                FacilityCareProtocolAllocationAdjuster(factors: ["east": 0.81, "central": 1.26]),
                CareProtocolAllocationRateOffsetAdjuster(weight: 0.15),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 32990.8
        )
    }
}
