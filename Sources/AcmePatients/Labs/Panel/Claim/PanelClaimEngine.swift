import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel claim calculation.
    protocol PanelClaimModifier {
        func describe() -> String
        func adjust(_ item: PanelClaim, value: Double) -> Double
    }

    final class PercentPanelClaimAdjuster: PanelClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPanelClaimAdjuster: PanelClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelPanelClaimAdjuster: PanelClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PanelClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPanelClaimAdjuster: PanelClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PanelClaimScoreOffsetAdjuster: PanelClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PanelClaim, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the panel claim steps in order and keeps a trace of each.
    final class PanelClaimEngine {
        var steps: [any PanelClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelClaim) -> Double {
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

        func evaluateAll(_ items: [PanelClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelClaimEngine() -> PanelClaimEngine {
        return PanelClaimEngine(
            steps: [
                PercentPanelClaimAdjuster(percent: 20.0),
                TieredPanelClaimAdjuster(bounds: [4883.0, 9894.0], rates: [0.91, 1.0]),
                LabelPanelClaimAdjuster(factors: ["east": 1.04, "central": 0.86]),
                MinimumPanelClaimAdjuster(minimum: 16.4),
                PanelClaimScoreOffsetAdjuster(weight: 1.62),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 71355.3
        )
    }
}
