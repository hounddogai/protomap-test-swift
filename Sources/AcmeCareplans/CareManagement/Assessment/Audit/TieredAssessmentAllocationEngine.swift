import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered assessment allocation calculation.
    protocol TieredAssessmentAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: TieredAssessmentAllocation, value: Double) -> Double
    }

    final class FlaggedTieredAssessmentAllocationAdjuster: TieredAssessmentAllocationAdjuster {
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

        func adjust(_ item: TieredAssessmentAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAssessmentAllocationStartsAtOffsetAdjuster: TieredAssessmentAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: TieredAssessmentAllocation, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingTieredAssessmentAllocationAdjuster: TieredAssessmentAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredAssessmentAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredAssessmentAllocationAdjuster: TieredAssessmentAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredAssessmentAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered assessment allocation steps in order and keeps a trace of each.
    final class TieredAssessmentAllocationEngine {
        var steps: [any TieredAssessmentAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredAssessmentAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredAssessmentAllocation) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [TieredAssessmentAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredAssessmentAllocationEngine(_ flags: Kit.Flags.Registry) -> TieredAssessmentAllocationEngine {
        return TieredAssessmentAllocationEngine(
            steps: [
                FlaggedTieredAssessmentAllocationAdjuster(
                    flags: flags,
                    flag: "tiered-assessment-allocation-adaptive",
                    percent: -7.6
                ),
                TieredAssessmentAllocationStartsAtOffsetAdjuster(weight: 1.19),
                RoundingTieredAssessmentAllocationAdjuster(step: 0.25),
                TieredTieredAssessmentAllocationAdjuster(
                    bounds: [542.0, 3398.0, 6883.0, 8119.0],
                    rates: [0.88, 0.83, 1.01, 1.02]
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 33569.7
        )
    }
}
