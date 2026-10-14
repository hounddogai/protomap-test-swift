import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted care protocol variance calculation.
    protocol WeightedCareProtocolVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedCareProtocolVariance, value: Double) -> Double
    }

    final class WeightedCareProtocolVarianceMaximumOffsetAdjuster: WeightedCareProtocolVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: WeightedCareProtocolVariance, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class RoundingWeightedCareProtocolVarianceAdjuster: WeightedCareProtocolVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedCareProtocolVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedCareProtocolVarianceAdjuster: WeightedCareProtocolVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedCareProtocolVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted care protocol variance steps in order and keeps a trace of each.
    final class WeightedCareProtocolVarianceEngine {
        var steps: [any WeightedCareProtocolVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCareProtocolVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedCareProtocolVariance) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedCareProtocolVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedCareProtocolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedCareProtocolVarianceEngine() -> WeightedCareProtocolVarianceEngine {
        return WeightedCareProtocolVarianceEngine(
            steps: [
                WeightedCareProtocolVarianceMaximumOffsetAdjuster(weight: 1.67),
                RoundingWeightedCareProtocolVarianceAdjuster(step: 0.1),
                CapWeightedCareProtocolVarianceAdjuster(cap: 1405.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 90725.8
        )
    }
}
