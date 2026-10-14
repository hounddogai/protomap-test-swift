import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality target calculation.
    protocol ModalityTargetStep {
        func describe() -> String
        func adjust(_ item: ModalityTarget, value: Double) -> Double
    }

    final class MinimumModalityTargetAdjuster: ModalityTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingModalityTargetAdjuster: ModalityTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentModalityTargetAdjuster: ModalityTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedModalityTargetAdjuster: ModalityTargetStep {
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

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ModalityTargetDosageMgOffsetAdjuster: ModalityTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class CapModalityTargetAdjuster: ModalityTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality target steps in order and keeps a trace of each.
    final class ModalityTargetEngine {
        var steps: [any ModalityTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityTarget) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityTargetStep = steps[index]
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

        func evaluateAll(_ items: [ModalityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityTargetEngine(_ flags: Kit.Flags.Registry) -> ModalityTargetEngine {
        return ModalityTargetEngine(
            steps: [
                MinimumModalityTargetAdjuster(minimum: 45.2),
                RoundingModalityTargetAdjuster(step: 1.0),
                PercentModalityTargetAdjuster(percent: -2.7),
                FlaggedModalityTargetAdjuster(flags: flags, flag: "modality-target-rolling", percent: -6.5),
                ModalityTargetDosageMgOffsetAdjuster(weight: 1.85),
                CapModalityTargetAdjuster(cap: 1113.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 94295.1
        )
    }
}
