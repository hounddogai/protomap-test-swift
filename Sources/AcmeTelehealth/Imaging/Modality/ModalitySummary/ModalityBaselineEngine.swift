import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality baseline calculation.
    protocol ModalityBaselineModifier {
        func describe() -> String
        func adjust(_ item: ModalityBaseline, value: Double) -> Double
    }

    final class FacilityModalityBaselineAdjuster: ModalityBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ModalityBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedModalityBaselineAdjuster: ModalityBaselineModifier {
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

        func adjust(_ item: ModalityBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingModalityBaselineAdjuster: ModalityBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ModalityBaselineWeightOffsetAdjuster: ModalityBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ModalityBaseline, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the modality baseline steps in order and keeps a trace of each.
    final class ModalityBaselineEngine {
        var steps: [any ModalityBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ModalityBaseline) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ModalityBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultModalityBaselineEngine(_ flags: Kit.Flags.Registry) -> ModalityBaselineEngine {
        return ModalityBaselineEngine(
            steps: [
                FacilityModalityBaselineAdjuster(factors: ["east": 1.36, "north": 0.9]),
                FlaggedModalityBaselineAdjuster(flags: flags, flag: "modality-baseline-strict", percent: 1.7),
                RoundingModalityBaselineAdjuster(step: 0.25),
                ModalityBaselineWeightOffsetAdjuster(weight: 1.52),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 42245.8
        )
    }
}
