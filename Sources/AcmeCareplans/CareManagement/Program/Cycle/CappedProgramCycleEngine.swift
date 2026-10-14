import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped program cycle calculation.
    protocol CappedProgramCycleAdjuster {
        func describe() -> String
        func adjust(_ item: CappedProgramCycle, value: Double) -> Double
    }

    final class RoundingCappedProgramCycleAdjuster: CappedProgramCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedProgramCycleAdjuster: CappedProgramCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedProgramCycleAdjuster: CappedProgramCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedProgramCycleAdjuster: CappedProgramCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitCappedProgramCycleAdjuster: CappedProgramCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedProgramCycleThresholdOffsetAdjuster: CappedProgramCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: CappedProgramCycle, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the capped program cycle steps in order and keeps a trace of each.
    final class CappedProgramCycleEngine {
        var steps: [any CappedProgramCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedProgramCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedProgramCycle) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedProgramCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedProgramCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedProgramCycleEngine() -> CappedProgramCycleEngine {
        return CappedProgramCycleEngine(
            steps: [
                RoundingCappedProgramCycleAdjuster(step: 0.1),
                MinimumCappedProgramCycleAdjuster(minimum: 36.0),
                PercentCappedProgramCycleAdjuster(percent: 21.9),
                CapCappedProgramCycleAdjuster(cap: 21209.0),
                UnitCappedProgramCycleAdjuster(factors: ["east": 0.98, "west": 1.22, "south": 0.8]),
                CappedProgramCycleThresholdOffsetAdjuster(weight: 0.3),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 99774.7
        )
    }
}
