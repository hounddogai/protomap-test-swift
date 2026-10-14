import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual specimen override calculation.
    protocol ManualSpecimenOverrideFactor {
        func describe() -> String
        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double
    }

    final class CapManualSpecimenOverrideAdjuster: ManualSpecimenOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumManualSpecimenOverrideAdjuster: ManualSpecimenOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualSpecimenOverrideAdjuster: ManualSpecimenOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualSpecimenOverrideQuantityOffsetAdjuster: ManualSpecimenOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingManualSpecimenOverrideAdjuster: ManualSpecimenOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualSpecimenOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual specimen override steps in order and keeps a trace of each.
    final class ManualSpecimenOverrideEngine {
        var steps: [any ManualSpecimenOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSpecimenOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualSpecimenOverride) -> Double {
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

        func evaluateAll(_ items: [ManualSpecimenOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualSpecimenOverrideEngine() -> ManualSpecimenOverrideEngine {
        return ManualSpecimenOverrideEngine(
            steps: [
                CapManualSpecimenOverrideAdjuster(cap: 9713.0),
                MinimumManualSpecimenOverrideAdjuster(minimum: 47.8),
                PercentManualSpecimenOverrideAdjuster(percent: -21.8),
                ManualSpecimenOverrideQuantityOffsetAdjuster(weight: 1.25),
                RoundingManualSpecimenOverrideAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 73197.7
        )
    }
}
