import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan checkpoint calculation.
    protocol AcuityPlanCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double
    }

    final class RoundingAcuityPlanCheckpointAdjuster: AcuityPlanCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAcuityPlanCheckpointAdjuster: AcuityPlanCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAcuityPlanCheckpointAdjuster: AcuityPlanCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAcuityPlanCheckpointAdjuster: AcuityPlanCheckpointAdjuster {
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

        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAcuityPlanCheckpointAdjuster: AcuityPlanCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan checkpoint steps in order and keeps a trace of each.
    final class AcuityPlanCheckpointEngine {
        var steps: [any AcuityPlanCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanCheckpoint) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanCheckpointEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanCheckpointEngine {
        return AcuityPlanCheckpointEngine(
            steps: [
                RoundingAcuityPlanCheckpointAdjuster(step: 0.05),
                TieredAcuityPlanCheckpointAdjuster(
                    bounds: [2526.0, 5027.0, 9162.0, 9830.0],
                    rates: [0.83, 1.14, 0.96, 1.18]
                ),
                NameAcuityPlanCheckpointAdjuster(factors: ["online": 0.75, "retail": 1.1, "north": 0.86]),
                FlaggedAcuityPlanCheckpointAdjuster(flags: flags, flag: "acuity-plan-checkpoint-manual", percent: 2.4),
                CapAcuityPlanCheckpointAdjuster(cap: 38469.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 72411.5
        )
    }
}
