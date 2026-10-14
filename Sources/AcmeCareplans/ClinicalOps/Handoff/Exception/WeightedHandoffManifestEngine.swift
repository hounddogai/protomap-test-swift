import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted handoff manifest calculation.
    protocol WeightedHandoffManifestFactor {
        func describe() -> String
        func adjust(_ item: WeightedHandoffManifest, value: Double) -> Double
    }

    final class MinimumWeightedHandoffManifestAdjuster: WeightedHandoffManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedHandoffManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleWeightedHandoffManifestAdjuster: WeightedHandoffManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedHandoffManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedHandoffManifestAdjuster: WeightedHandoffManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedHandoffManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedHandoffManifestAdjuster: WeightedHandoffManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedHandoffManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted handoff manifest steps in order and keeps a trace of each.
    final class WeightedHandoffManifestEngine {
        var steps: [any WeightedHandoffManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedHandoffManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedHandoffManifest) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [WeightedHandoffManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedHandoffManifestEngine() -> WeightedHandoffManifestEngine {
        return WeightedHandoffManifestEngine(
            steps: [
                MinimumWeightedHandoffManifestAdjuster(minimum: 37.3),
                TitleWeightedHandoffManifestAdjuster(factors: ["south": 1.21, "online": 0.9, "west": 1.07]),
                RoundingWeightedHandoffManifestAdjuster(step: 0.5),
                PercentWeightedHandoffManifestAdjuster(percent: -9.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 2462.9
        )
    }
}
