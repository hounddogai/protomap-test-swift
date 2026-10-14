import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol preference calculation.
    protocol CareProtocolPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolPreference, value: Double) -> Double
    }

    final class CareProtocolPreferenceRefillsOffsetAdjuster: CareProtocolPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CareProtocolPreference, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingCareProtocolPreferenceAdjuster: CareProtocolPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCareProtocolPreferenceAdjuster: CareProtocolPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareProtocolPreferenceAdjuster: CareProtocolPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care protocol preference steps in order and keeps a trace of each.
    final class CareProtocolPreferenceEngine {
        var steps: [any CareProtocolPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolPreference) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CareProtocolPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolPreferenceEngine() -> CareProtocolPreferenceEngine {
        return CareProtocolPreferenceEngine(
            steps: [
                CareProtocolPreferenceRefillsOffsetAdjuster(weight: 1.01),
                RoundingCareProtocolPreferenceAdjuster(step: 1.0),
                CapCareProtocolPreferenceAdjuster(cap: 27390.0),
                MinimumCareProtocolPreferenceAdjuster(minimum: 36.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 42930.5
        )
    }
}
