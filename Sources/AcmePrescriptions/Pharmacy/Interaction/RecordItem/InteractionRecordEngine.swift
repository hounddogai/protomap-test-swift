import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction record calculation.
    protocol InteractionRecordStep {
        func describe() -> String
        func adjust(_ item: InteractionRecord, value: Double) -> Double
    }

    final class InteractionRecordUpdatedAtOffsetAdjuster: InteractionRecordStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: InteractionRecord, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapInteractionRecordAdjuster: InteractionRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentInteractionRecordAdjuster: InteractionRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInteractionRecordAdjuster: InteractionRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInteractionRecordAdjuster: InteractionRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the interaction record steps in order and keeps a trace of each.
    final class InteractionRecordEngine {
        var steps: [any InteractionRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionRecord) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [InteractionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionRecordEngine() -> InteractionRecordEngine {
        return InteractionRecordEngine(
            steps: [
                InteractionRecordUpdatedAtOffsetAdjuster(weight: 1.25),
                CapInteractionRecordAdjuster(cap: 24178.0),
                PercentInteractionRecordAdjuster(percent: -10.7),
                RoundingInteractionRecordAdjuster(step: 0.05),
                TieredInteractionRecordAdjuster(bounds: [1747.0, 2894.0, 3222.0], rates: [1.09, 0.98, 1.02]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 43232.9
        )
    }
}
