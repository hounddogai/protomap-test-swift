import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel variance calculation.
    protocol PanelVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: PanelVariance, value: Double) -> Double
    }

    final class TieredPanelVarianceAdjuster: PanelVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelPanelVarianceAdjuster: PanelVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPanelVarianceAdjuster: PanelVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PanelVarianceGraceDaysOffsetAdjuster: PanelVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class PercentPanelVarianceAdjuster: PanelVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPanelVarianceAdjuster: PanelVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the panel variance steps in order and keeps a trace of each.
    final class PanelVarianceEngine {
        var steps: [any PanelVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [PanelVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelVarianceEngine() -> PanelVarianceEngine {
        return PanelVarianceEngine(
            steps: [
                TieredPanelVarianceAdjuster(bounds: [2606.0, 3091.0, 4888.0, 7845.0], rates: [0.98, 1.08, 1.04, 1.0]),
                LabelPanelVarianceAdjuster(factors: ["online": 1.37, "east": 0.79, "central": 1.24]),
                CapPanelVarianceAdjuster(cap: 9151.0),
                PanelVarianceGraceDaysOffsetAdjuster(weight: 1.46),
                PercentPanelVarianceAdjuster(percent: -0.5),
                RoundingPanelVarianceAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 90212.6
        )
    }
}
