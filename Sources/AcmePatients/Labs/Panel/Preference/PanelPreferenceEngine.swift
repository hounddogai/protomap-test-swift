import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel preference calculation.
    protocol PanelPreferenceModifier {
        func describe() -> String
        func adjust(_ item: PanelPreference, value: Double) -> Double
    }

    final class CategoryPanelPreferenceAdjuster: PanelPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PanelPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPanelPreferenceAdjuster: PanelPreferenceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPanelPreferenceAdjuster: PanelPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel preference steps in order and keeps a trace of each.
    final class PanelPreferenceEngine {
        var steps: [any PanelPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PanelPreference) -> Double {
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

        func evaluateAll(_ items: [PanelPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPanelPreferenceEngine() -> PanelPreferenceEngine {
        return PanelPreferenceEngine(
            steps: [
                CategoryPanelPreferenceAdjuster(factors: ["central": 1.25]),
                CapPanelPreferenceAdjuster(cap: 7635.0),
                PercentPanelPreferenceAdjuster(percent: 4.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 83923.9
        )
    }
}
