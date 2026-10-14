import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality cycle calculation.
    protocol ModalityCycleFactor {
        func describe() -> String
        func adjust(_ item: ModalityCycle, value: Double) -> Double
    }

    final class ModalityCycleRevisionOffsetAdjuster: ModalityCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ModalityCycle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class MinimumModalityCycleAdjuster: ModalityCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingModalityCycleAdjuster: ModalityCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapModalityCycleAdjuster: ModalityCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality cycle steps in order and keeps a trace of each.
    final class ModalityCycleEngine {
        var steps: [any ModalityCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityCycle) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ModalityCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityCycleEngine() -> ModalityCycleEngine {
        return ModalityCycleEngine(
            steps: [
                ModalityCycleRevisionOffsetAdjuster(weight: 0.04),
                MinimumModalityCycleAdjuster(minimum: 46.5),
                RoundingModalityCycleAdjuster(step: 0.25),
                CapModalityCycleAdjuster(cap: 13083.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 41412.0
        )
    }
}
