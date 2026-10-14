import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary order set cycle calculation.
    protocol PrimaryOrderSetCycleStep {
        func describe() -> String
        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double
    }

    final class PrimaryOrderSetCycleQuantityOffsetAdjuster: PrimaryOrderSetCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedPrimaryOrderSetCycleAdjuster: PrimaryOrderSetCycleStep {
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

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryOrderSetCycleAdjuster: PrimaryOrderSetCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryOrderSetCycleAdjuster: PrimaryOrderSetCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryOrderSetCycleAdjuster: PrimaryOrderSetCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentPrimaryOrderSetCycleAdjuster: PrimaryOrderSetCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrimaryOrderSetCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary order set cycle steps in order and keeps a trace of each.
    final class PrimaryOrderSetCycleEngine {
        var steps: [any PrimaryOrderSetCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOrderSetCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryOrderSetCycle) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryOrderSetCycleStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryOrderSetCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryOrderSetCycleEngine(_ flags: Kit.Flags.Registry) -> PrimaryOrderSetCycleEngine {
        return PrimaryOrderSetCycleEngine(
            steps: [
                PrimaryOrderSetCycleQuantityOffsetAdjuster(weight: 0.93),
                FlaggedPrimaryOrderSetCycleAdjuster(
                    flags: flags,
                    flag: "primary-order-set-cycle-lenient",
                    percent: -9.7
                ),
                TieredPrimaryOrderSetCycleAdjuster(bounds: [4665.0, 8302.0], rates: [1.18, 0.91]),
                RoundingPrimaryOrderSetCycleAdjuster(step: 0.1),
                CapPrimaryOrderSetCycleAdjuster(cap: 1296.0),
                SegmentPrimaryOrderSetCycleAdjuster(factors: ["east": 0.82, "south": 1.09]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 18125.3
        )
    }
}
