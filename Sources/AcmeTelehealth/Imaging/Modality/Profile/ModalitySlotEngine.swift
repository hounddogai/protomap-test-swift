import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality slot calculation.
    protocol ModalitySlotStep {
        func describe() -> String
        func adjust(_ item: ModalitySlot, value: Double) -> Double
    }

    final class FlaggedModalitySlotAdjuster: ModalitySlotStep {
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

        func adjust(_ item: ModalitySlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingModalitySlotAdjuster: ModalitySlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalitySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentModalitySlotAdjuster: ModalitySlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalitySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality slot steps in order and keeps a trace of each.
    final class ModalitySlotEngine {
        var steps: [any ModalitySlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalitySlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalitySlot) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ModalitySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalitySlotEngine(_ flags: Kit.Flags.Registry) -> ModalitySlotEngine {
        return ModalitySlotEngine(
            steps: [
                FlaggedModalitySlotAdjuster(flags: flags, flag: "modality-slot-tiered", percent: 9.9),
                RoundingModalitySlotAdjuster(step: 0.05),
                PercentModalitySlotAdjuster(percent: 6.3),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 60909.3
        )
    }
}
