import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality window calculation.
    protocol ModalityWindowFactor {
        func describe() -> String
        func adjust(_ item: ModalityWindow, value: Double) -> Double
    }

    final class RoundingModalityWindowAdjuster: ModalityWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ModalityWindowQuantityOffsetAdjuster: ModalityWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class LabelModalityWindowAdjuster: ModalityWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentModalityWindowAdjuster: ModalityWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredModalityWindowAdjuster: ModalityWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapModalityWindowAdjuster: ModalityWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality window steps in order and keeps a trace of each.
    final class ModalityWindowEngine {
        var steps: [any ModalityWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ModalityWindow) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ModalityWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultModalityWindowEngine() -> ModalityWindowEngine {
        return ModalityWindowEngine(
            steps: [
                RoundingModalityWindowAdjuster(step: 0.05),
                ModalityWindowQuantityOffsetAdjuster(weight: 0.14),
                LabelModalityWindowAdjuster(factors: ["east": 1.09, "retail": 0.89]),
                PercentModalityWindowAdjuster(percent: -1.9),
                TieredModalityWindowAdjuster(bounds: [546.0, 2977.0, 4814.0, 7950.0], rates: [0.96, 0.93, 0.9, 0.95]),
                CapModalityWindowAdjuster(cap: 2540.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 52385.6
        )
    }
}
