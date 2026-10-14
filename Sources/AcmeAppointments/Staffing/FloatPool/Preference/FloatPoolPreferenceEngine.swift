import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool preference calculation.
    protocol FloatPoolPreferenceFactor {
        func describe() -> String
        func adjust(_ item: FloatPoolPreference, value: Double) -> Double
    }

    final class RoundingFloatPoolPreferenceAdjuster: FloatPoolPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFloatPoolPreferenceAdjuster: FloatPoolPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolPreferenceAdjuster: FloatPoolPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardFloatPoolPreferenceAdjuster: FloatPoolPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FloatPoolPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FloatPoolPreferenceCreatedAtOffsetAdjuster: FloatPoolPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: FloatPoolPreference, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the float pool preference steps in order and keeps a trace of each.
    final class FloatPoolPreferenceEngine {
        var steps: [any FloatPoolPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolPreference) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FloatPoolPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolPreferenceEngine() -> FloatPoolPreferenceEngine {
        return FloatPoolPreferenceEngine(
            steps: [
                RoundingFloatPoolPreferenceAdjuster(step: 0.1),
                PercentFloatPoolPreferenceAdjuster(percent: -19.1),
                CapFloatPoolPreferenceAdjuster(cap: 12633.0),
                WardFloatPoolPreferenceAdjuster(factors: ["west": 1.21, "east": 1.05]),
                FloatPoolPreferenceCreatedAtOffsetAdjuster(weight: 1.52),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 38330.6
        )
    }
}
