import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default alert profile calculation.
    protocol DefaultAlertProfileAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultAlertProfile, value: Double) -> Double
    }

    final class MinimumDefaultAlertProfileAdjuster: DefaultAlertProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAlertProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleDefaultAlertProfileAdjuster: DefaultAlertProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultAlertProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultAlertProfileMaximumOffsetAdjuster: DefaultAlertProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: DefaultAlertProfile, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapDefaultAlertProfileAdjuster: DefaultAlertProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAlertProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default alert profile steps in order and keeps a trace of each.
    final class DefaultAlertProfileEngine {
        var steps: [any DefaultAlertProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAlertProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultAlertProfile) -> Double {
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

        func evaluateAll(_ items: [DefaultAlertProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultAlertProfileEngine() -> DefaultAlertProfileEngine {
        return DefaultAlertProfileEngine(
            steps: [
                MinimumDefaultAlertProfileAdjuster(minimum: 5.5),
                TitleDefaultAlertProfileAdjuster(factors: ["east": 0.82]),
                DefaultAlertProfileMaximumOffsetAdjuster(weight: 0.98),
                CapDefaultAlertProfileAdjuster(cap: 28446.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 83959.0
        )
    }
}
