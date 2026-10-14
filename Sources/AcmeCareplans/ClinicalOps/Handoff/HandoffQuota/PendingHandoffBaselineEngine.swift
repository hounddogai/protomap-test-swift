import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending handoff baseline calculation.
    protocol PendingHandoffBaselineFactor {
        func describe() -> String
        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double
    }

    final class CategoryPendingHandoffBaselineAdjuster: PendingHandoffBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingHandoffBaselineAdjuster: PendingHandoffBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingHandoffBaselineDurationMinutesOffsetAdjuster: PendingHandoffBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedPendingHandoffBaselineAdjuster: PendingHandoffBaselineFactor {
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

        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingHandoffBaselineAdjuster: PendingHandoffBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingHandoffBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending handoff baseline steps in order and keeps a trace of each.
    final class PendingHandoffBaselineEngine {
        var steps: [any PendingHandoffBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingHandoffBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingHandoffBaseline) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [PendingHandoffBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingHandoffBaselineEngine(_ flags: Kit.Flags.Registry) -> PendingHandoffBaselineEngine {
        return PendingHandoffBaselineEngine(
            steps: [
                CategoryPendingHandoffBaselineAdjuster(factors: ["south": 1.19, "online": 0.88]),
                PercentPendingHandoffBaselineAdjuster(percent: -20.5),
                PendingHandoffBaselineDurationMinutesOffsetAdjuster(weight: 1.97),
                FlaggedPendingHandoffBaselineAdjuster(
                    flags: flags,
                    flag: "pending-handoff-baseline-weighted",
                    percent: -5.2
                ),
                RoundingPendingHandoffBaselineAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 29568.9
        )
    }
}
