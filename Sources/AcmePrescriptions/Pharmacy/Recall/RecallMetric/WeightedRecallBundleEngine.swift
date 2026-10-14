import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted recall bundle calculation.
    protocol WeightedRecallBundleAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double
    }

    final class WeightedRecallBundleCreatedAtOffsetAdjuster: WeightedRecallBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class TitleWeightedRecallBundleAdjuster: WeightedRecallBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedRecallBundleAdjuster: WeightedRecallBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedRecallBundleAdjuster: WeightedRecallBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedRecallBundleAdjuster: WeightedRecallBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedRecallBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted recall bundle steps in order and keeps a trace of each.
    final class WeightedRecallBundleEngine {
        var steps: [any WeightedRecallBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRecallBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedRecallBundle) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WeightedRecallBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedRecallBundleEngine() -> WeightedRecallBundleEngine {
        return WeightedRecallBundleEngine(
            steps: [
                WeightedRecallBundleCreatedAtOffsetAdjuster(weight: 1.12),
                TitleWeightedRecallBundleAdjuster(factors: ["central": 1.22]),
                PercentWeightedRecallBundleAdjuster(percent: -17.6),
                MinimumWeightedRecallBundleAdjuster(minimum: 18.5),
                CapWeightedRecallBundleAdjuster(cap: 29663.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 97992.6
        )
    }
}
