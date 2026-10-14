import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending program estimate calculation.
    protocol PendingProgramEstimateStep {
        func describe() -> String
        func adjust(_ item: PendingProgramEstimate, value: Double) -> Double
    }

    final class NamePendingProgramEstimateAdjuster: PendingProgramEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingProgramEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingProgramEstimateAdjuster: PendingProgramEstimateStep {
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

        func adjust(_ item: PendingProgramEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingProgramEstimateAdjuster: PendingProgramEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingProgramEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PendingProgramEstimateGraceDaysOffsetAdjuster: PendingProgramEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingProgramEstimate, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the pending program estimate steps in order and keeps a trace of each.
    final class PendingProgramEstimateEngine {
        var steps: [any PendingProgramEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingProgramEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingProgramEstimate) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingProgramEstimateStep = steps[index]
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

        func evaluateAll(_ items: [PendingProgramEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingProgramEstimateEngine(_ flags: Kit.Flags.Registry) -> PendingProgramEstimateEngine {
        return PendingProgramEstimateEngine(
            steps: [
                NamePendingProgramEstimateAdjuster(factors: ["west": 1.22, "north": 0.81, "online": 0.88]),
                FlaggedPendingProgramEstimateAdjuster(
                    flags: flags,
                    flag: "pending-program-estimate-capped",
                    percent: 2.9
                ),
                RoundingPendingProgramEstimateAdjuster(step: 1.0),
                PendingProgramEstimateGraceDaysOffsetAdjuster(weight: 0.53),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 39241.5
        )
    }
}
